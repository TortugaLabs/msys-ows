# msys-ows

My adhoc config management scripts for OpenWRT

## Scripts

- msys-init : initializes a new switch, or update a switch
- msys-deploy : Install files into switches
- msys-runner : Applies configuration to switch ... runs on the switch
		itself.

## msys-init

If telnet is active (i.e. factory reset), then
itnitializes root user and copies configuration files.
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

Copies scripts to switch and optionally run them.  It does not
copy configurationfiles. (Use `msys-init` for this.)

Arguments:

- --lib=<path> : directory containing code (env:MSYS_LIBDIR), used
    to load dependant libraries
- --payload=<path> : directory containing code to deploy
- --install=<path> : directory where the code will be deployed to
- --[no-]autorun : run (or not run) deploy
- additional options are the target hosts

## Failsafe mode

For the TL-WRT1043ND-V1.

- Power on device
- Wait for the `SYS` LED starts blinking.
- Press the `QSS` button repeatedly until the `SYS` LED starts blinking rapidly.
- You can now access the device using `telnet` to `192.168.1.1/24` on the LAN ports.
- To manually configure an IP address:
  - `ip address add 192.168.1.16/24 dev enp0s20f0u2u1`

### Things to do after entering Failsafe mode

- `mount_root`
  - make the root filesystem available and writeable.
- `firstboot`
  - factory reset the device.
  - Last I tested, you sort of need do `mount_root` first for
    this to work properly.
  - All output is send to /dev/kmsg, but it is not
    really interactive.  It is just asking for:
  - `jffs2reset: This will erase all settings and remove any installed packages. Are you sure? [N/y]`
  - So just enter `y` follow by `ENTER` and you are done.

# TIPS

I usually run with some configurations settings in a file.  Then
execute scripts as such:

```
../msys-ows.env ./msys-deploy target-ip
```



