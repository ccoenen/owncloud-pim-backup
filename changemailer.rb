require 'rugged'
require 'mail'
require 'mustache'
require 'yaml'

config = YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), 'config.yml'))

mail_template =<<EOT
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
  {{{body}}}
</body>
</html>
EOT

change_template =<<EOT
  <div class="patch">
    <h1>{{status}}: {{{filename}}}</h1>
    <table class="diff">
      <tr>
        <td width="33%"><pre>{{left}}</pre></td>
        <td width="33%"><pre>{{right}}</pre></td>
        <td width="33%"><pre>{{{patch}}}</pre></td>
      </tr>
    </table>
  </div>
EOT



repo = Rugged::Repository.new('calendar')
head_commit = repo.head.target
diff = head_commit.parents[0].diff(head_commit)
diff.find_similar!(renames: true)


html_chunks = diff.patches.map do |patch|
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

  data = {
    status: delta.status,
    filename: delta.old_file[:path] == delta.new_file[:path] ? delta.new_file[:path] : "<br>old: #{delta.old_file[:path]}<br>new: #{delta.new_file[:path]}",
    left: left,
    right: right,
    patch: patch.flatten!.join
  }

  Mustache.render(change_template, data)
end


mail = Mail.new do
  from     config["mailer"]["from"]
  to       config["mailer"]["to"]
  subject  "#{diff.deltas.length} items changed"

  text_part do
    body diff.patch
  end

  html_part do
    content_type 'text/html; charset=UTF-8'
    body Mustache.render(mail_template, {body: html_chunks.join})
  end

  add_file :filename => 'changes.txt', :content => diff.patch
end

mail.delivery_method :sendmail

mail.deliver

