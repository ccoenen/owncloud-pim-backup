require 'rugged'
require 'mail'
require 'mustache'
require 'yaml'

config = YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'config.yml'))

html_mail_template =<<EOT
<html>
<head>
  <style>
    table.diff {
      width: 100%;
      border-bottom: 1px solid rgb(200, 200, 200);
      margin-bottom: 20px;
    }
    h1 {
      font-size: 12pt;
    }
    ins {
      color: rgb(0, 70, 0);
      background-color: rgb(240, 255, 250);
    }
    del {
      color: rgb(70, 0, 0);
      background-color: rgb(255, 240, 250);
    }
  </style>
</head>
<body>
  {{#changes}}
  <div class="patch">
    <h1>{{status}}: {{old_filename}}{{#new_filename}}<br>to {{.}}{{/new_filename}}</h1>
    <table class="diff">
      <tr>
        <td width="33%"><pre>{{left}}</pre></td>
        <td width="33%"><pre>{{right}}</pre></td>
        <td width="33%"><pre>{{{patch}}}</pre></td>
      </tr>
    </table>
  </div>
  {{/changes}}
</body>
</html>
EOT

text_mail_template =<<EOT
Changes to the following items:
{{#changes}}
- {{status}} {{old_filename}}{{#new_filename}} => {{.}}{{/new_filename}}
{{/changes}}
EOT


repo = Rugged::Repository.new('calendar')
head_commit = repo.head.target
diff = head_commit.parents[0].diff(head_commit)
diff.find_similar!(renames: true)


changes = diff.patches.map do |patch|
  delta = patch.delta
  left = repo.lookup(delta.old_file[:oid]).read_raw.data rescue ""
  right = repo.lookup(delta.new_file[:oid]).read_raw.data rescue ""
  patch = patch.hunks.map do |h|
    lines = h.lines.map do |l|
      tag = case l.line_origin
      when :addition
        "ins"
      when :deletion
        "del"
      else
        "span"
      end
      "<#{tag}>#{l.content}</#{tag}>"
    end
    [h.header, lines]
  end

  {
    status: delta.status,
    old_filename: delta.old_file[:path],
    new_filename: delta.old_file[:path] != delta.new_file[:path] ? delta.new_file[:path] : nil,
    left: left,
    right: right,
    patch: patch.flatten!.join
  }
end


mail = Mail.new do
  from     config["mailer"]["from"]
  to       config["mailer"]["to"]
  subject  "#{diff.deltas.length} items changed"
end
mail.part :content_type => 'multipart/alternative' do |p|
  p.text_part = Mail::Part.new do
    content_type 'text/plain; charset="UTF-8'
    body Mustache.render(text_mail_template, {changes: changes})
  end

  p.html_part = Mail::Part.new do
    content_type 'text/html; charset=UTF-8'
    body Mustache.render(html_mail_template, {changes: changes})
  end
end
mail.attachments['changes.diff'] = {content: diff.patch, mime_type: 'text/x-diff'}


mail.delivery_method :sendmail

mail.deliver

