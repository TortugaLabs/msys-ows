#
# Basic Openwrt stuff
#

# Check version details
umask 022
[ ! -f /etc/openwrt_version ] \
    && fatal "Invalid device type (missing openwrt_version)" || :
openwrt_version=$(cat /etc/openwrt_version)
[ ! -f /etc/openwrt_release ] \
    && fatal "Invalid device type (missing openwrt_release)" || :
. /etc/openwrt_release

# Check VLANs and set the WIFI status
WIFI=$(
  for vnet in $VLANS
  do
    wifi=$(get ${vnet}_WIFI 2>/dev/null)
    if $wifi ; then
      echo true
      exit
    fi
  done
  echo false
)

# Load optional modules
for module in ${MSYS_MODULES}
do
  if [ -f $libdir/$module.sh ] ; then
    . $libdir/$module.sh
  else
    warn "Missing module: $module"
  fi
done

case "$openwrt_version" in
  15.05.1)
    enable sysfixtime boot system sysctl log rpcd network cron dropbear done led sysntpd
    ;;
  *)
    fatal "Unsupported openwrt_version ($openwrt_version)"
    ;;
esac

#
# Basic configuration
#
(fixfile /etc/config/system || :)<<-EOF
	config system
	    option hostname "$SYSNAME"
	    option timezone "$(awk -vFS=":" '$1 == "'$TZ'" { print $2 }' $libdir/tz.dat)"
	    # send log message to central log server...
	    $( [ -n "${OWS_LOGIP:-}" ] && echo "option log_ip \"$OWS_LOGIP\"" || : )

	config timeserver ntp
	    $( for ip in $OWS_NTP ; do echo "list server $ip" ; done )
	    option enabled 1
	    option enable_server 0

	$(opt_fn config_led)
	EOF
restart boot /etc/config/system

# Figure out if OWS_VLAN has wifi...
ows_opt_type_bridge=''
if $WIFI ; then
  ows_opt_type_bridge="$(
      for vnet in $VLANS
      do
	vid=$(get ${vnet}_VLAN_ID 2>/dev/null)
	[ $vid -ne $OWS_VLAN ] && continue || :
	wifi=$(get ${vnet}_WIFI 2>/dev/null)
	$wifi || break
	ssid=$(get ${vnet}_WIFI_SSID '' 2>/dev/null)
	[ -z "$ssid" ] && break || :
	echo option type bridge
	break
      done
  )"
fi

(fixfile /etc/config/network || :)<<-EOF
	config interface 'loopback'
	    option ifname 'lo'
	    option proto 'static'
	    option ipaddr '127.0.0.1'
	    option netmask '255.0.0.0'

	config globals 'globals'
	    option ula_prefix 'fda9:fa83:29d5::/48'

	config interface vl$OWS_VLAN
	    option ifname eth0.$OWS_VLAN
	    $ows_opt_type_bridge
	    option force_link 1
	    option proto static
	    option ipaddr $OWS_SN.$NODEID
	    option netmask $OWS_NETMASK
	    option gateway $OWS_GW

	$(opt_fn config_wifi_if)

	$(opt_fn config_switch)
	EOF

opt_fn config_wifi

restart network /etc/config/network /etc/config/wireless

if [ -L /etc/resolv.conf ] ; then
  echo "Removing DHCP resolv.conf"
  rm -f /etc/resolv.conf
fi
(fixfile /etc/resolv.conf || :)<<-EOF
domain $OWS_DOMAIN
$(
for i in $OWS_NS
do
  echo "nameserver $i"
done
)
EOF

script_install srv

#~ # install xinetd (for muninlite)
#~ if [ -z "$(opkg info xinetd)" ] ; then
  #~ # Not installed yet...
  #~ opkg install $libdir/xinetd_2.3.15-3_ar71xx.ipk
  #~ enable xinetd
#~ fi

#~ # Configure munin-node/muninlite
#~ script_install --target=/usr/sbin munin-node
#~ (fixfile /etc/xinetd.d/munin || : )<<-EOF
#~ service munin
#~ {
	#~ socket_type	= stream
	#~ protocol	= tcp
	#~ wait		= no
	#~ user		= root
	#~ group		= root
	#~ server		= /usr/sbin/munin-node
	#~ disable		= no
#~ }
#~ EOF
#~ restart xinetd /etc/xinetd.d/munin /etc/xinetd.conf
