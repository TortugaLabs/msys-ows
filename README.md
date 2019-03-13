# msys-ows

My adhoc config management scripts for OpenWRT

## Scripts

- msys-init : initializes a new switch
- msys-deploy : Install files into switches
- msys-runner : Applies configuration to switch ... runs on the switch
		itself.

## msys-init

If telnet is active (i.e. factory reset), then
  Initializes root user and copies configuration files.
Copies configuration files and then runs deploy.

This script can be used for initialization and later for
updating config files.

Arguments:

- --cfg=<file> : config file (env:MSYS_CFG)
- --secrets=<file> : secrets file (env:MSYS_SECRETS)
- --lib=<path> : directory containing code (env:MSYS_LIBDIR), used
    to load dependant libraries and passed to deploy later
- --payload=<path> : directory that will be passed to deploy laer
- --passwd=<random> : default root password (env:MSYS_PASSWD)
- --auth-keys=<file> : ssh public key (env:MSYS_AUTHKEYS contains
    the keys themselves)
- --[no-]autorun : passed to deploy
- additional options are the target hosts

## msys-deploy

Copies configuration scripts to switch and optionally run them.

Arguments:

- --lib=<path> : directory containing code (env:MSYS_LIBDIR), used
    to load dependant libraries
- --payload=<path> : directory containing code to deploy
- --install=<path> : directory where the code will be deployed to
- --[no-]autorun : run (or not run) deploy
- additional options are the target hosts


