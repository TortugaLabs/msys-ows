#!/bin/sh
script_install --target=/usr/sbin munin-node xinetd-bin/xinetd
fixfile -N --mode=755 /etc/init.d/xinetd < $libdir/xinetd-bin/init.sh
fixfile -N --mode=644 /etc/xinetd.conf < $libdir/xinetd-bin/xinetd.conf
mkdir -p /etc/xinetd.d
enable xinetd
fixfile -N /etc/xinetd.d/munin <<-EOF
service munin
{
	socket_type	= stream
	protocol	= tcp
	wait		= no
	user		= root
	group		= root
	server		= /usr/sbin/munin-node
	disable		= no
}
EOF
restart xinetd /etc/xinetd.d/munin /etc/xinetd.conf
