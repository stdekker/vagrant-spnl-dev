# Vagrant spnl.dev (debian/jessie64)

Author: Stijn Dekker
Version: 0.1

This is SP.nl development virtual machine for vagrant.
The basics are automated, but a lot of work needs to be done in order for the machine to fully work.
So, when it finally works, guard it with your life.

When all services are configured properly, the common admin password is 'rootpass'.

# Usage instructions

There are a few things you need to for the script to run properly. 
Suggestions to automate this further are very welcome.

## Adjust the provisioning script
You might want to change the provisioning script to fit your credentials.

Look for:
git config --global user.name "User Name"
git config --global user.email "email@example.com"

And

https://github.com/SPWebteam/spnl.git is a private repo, so a password is needed:
https://username:password@github.com/SPWebteam/spnl.git

## SQL dump and files importing
By default the script uses Hoppigners 'create seeds' function, to do the basic setup of the development environment. 
But if you put an spnl_d7x.sql sql dump in the database, it will import that file instead of creating dummy content.

## Manual config

The following things have not been automated / provisioned (for now):

- Set upload limit in php to 128M
- Set max post size to 128M
- Setting memory limit to something nice ()
- Enabling opcahce: opcache.enable=1
- Adding varnish secret key to cnf/settings.local.php
- Correct varnish.spnl.vcl (the one in the git-repo is broken)



