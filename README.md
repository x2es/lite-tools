The Lite Tools
==============

This is the lite tools "pack" which is helpfull in several aspects of programming life.

## Safe and Verbose

All this tools (almost all by the season 2023) always explains which actions will be performed 
and asks a permision for making changes.

Hope this is not obtrussive.

### NOTE

Some tools may need Mac adoption. Drop an issue or PR if so.

## Overview

### Wait

Waiter tools useful for automation and scripts composition.

* `wait/wait-port 3000 && notify-send Ready` - wait for TCP port to start listen.
* `wait/wait-http http://localhost:3000/ && notify-send Ready` - wait for http service to be ready.
* `docker/wait-container` - see Docker section

### Docker

NOTE: assumed `docker` wokrs without `sudo`

* `docker/container-id` - get hash by service name. Be specific to get single-line output. Used in other tools.
* `docker/is-container mysql-1 && echo ok || echo no` - check if container exist. Be specific, you know.
* `docker/console mysql-1` - jump into console by service name, not hash. Be specific.
* `docker/console_root mysql-1` - jum into console as root.
* `docker/wait-container mysql-1 && docker/console mysql-1` - wait for container ready

### Rails

* `rails/rspec-modified` - invoke rspec only for changed specs. Use `VS_BRANCH=feature` (default: `master`).
* `rails/rubocop-staged` - invoke RuboCop for files staged to commit. Tip: accepts params like `-a` or `-A`.
* `rails/gem-outdated-by-semver` - split `gem outdated` output by semver on priority groups with stat.

## As Is

All this provided as is... you know :)

Copylefted by x@ES

