# Owncloud PIM Backup

Backup tool to export your owncloud contacts to vcf-files, storing them in a git-controlled directory.

The output is very suitable for summary emails.

## requirements

* ruby 1.9 or later
* bundler
* git

## setup

* clone this repository
* run `bundle install`
* copy `config.yml.example` to `config.yml`
* change `config.yml` to contain your database information
* find out the addressbook's id, this will be in the table `oc_contacts_addressbooks`, and put it into `config.yml` as well
* create a `contacts` directory (or, alternatively, point the config to your desired contacts location)
* run `git init´in that location

## use

Whenever you feel like it you can run the script like this

    cd your-owncloud-pim-clone
    ./owncloud-pim-backup

## automated use

I run this script every night from a cronjob. Easy crontab:

    # a notification address. Change to your own, obviously
    MAILTO=notify-me@example.com
    
    # the actual calling of this script, every day at 04:00 in the night.
    0 4 * * * bash -l -c 'cd your-owncloud-pim-clone; ./owncloud-pim-backup'

To specify a subject line, i have a slightly more complicated crontab:

    # sets encoding and subject.
    # Don't forget to add your email address at the very end!
    0 4 * * * bash -l -c 'cd your-owncloud-pim-clone; ./owncloud-pim-backup | mail -a "Content-Type: text/plain; charset=UTF-8" -s "OwnCloud PIM Change Summary" notify-me@example.com'

