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
* change `config.yml` to contain your database information and desired from/to email addresses
* find out the addressbook's id, this will be in the table `oc_contacts_addressbooks`, and put it into `config.yml` as well
* create a `contacts` directory (or, alternatively, point the config to your desired contacts location)
* run `git init` in that location

## use

Whenever you feel like it you can run the script like this

    cd your-owncloud-pim-clone
    ./owncloud-pim-backup

## automated use

I run this script every night from a cronjob. Easy crontab:

    # the actual calling of this script, every day at 04:00 in the night.
    0 4 * * * bash -l -c 'cd your-owncloud-pim-clone; ./owncloud-pim-backup'

## free software

This is free software, released under MIT License. Use at your own risk.
