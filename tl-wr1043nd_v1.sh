#!/bin/sh
#
# Stuff specific to the TL-WR1043ND v1
#

config_led() {
  cat <<-EOF
	config led 'led_usb'
	    option name 'USB'
	    option sysfs 'tp-link:green:usb'
	    option trigger 'usbdev'
	    option dev '1-1'
	    option interval '50'

	config led 'led_wlan'
	    option name 'WLAN'
	    option sysfs 'tp-link:green:wlan'
	    option trigger 'phy0tpt'
	EOF
}

config_wifi_if() {
  $WIFI || return 0
  if [ -z "${WIFI_WCHAN:-}" ] ; then
    warn "Missing WIFI_WCHAN"
    return 0
  fi
  
  local vnet ssid vid
  for vnet in $VLANS
  do
    vid=$(get ${vnet}_VLAN_ID)
    ssid=$(get ${vnet}_WIFI_SSID '')
    [ -z "$ssid" ] && continue || :
    echo "config interface vl$vid"
    echo "    option ifname eth0.$vid"
    echo "    option type bridge"
    echo ''
  done
}

config_wifi_radio() {
  $WIFI || return 0
  if [ -z "${WIFI_WCHAN:-}" ] ; then
    warn "Missing WIFI_WCHAN"
    return 0
  fi
  local radio="$1" ; shift

  local vnet
  for vnet in $VLANS
  do
    local vid=$(get ${vnet}_VLAN_ID)
    local ssid=$(get ${vnet}_WIFI_SSID '') ; [ -z "$ssid" ] && continue || :
    local psk=$(get ${vnet}_WIFI_PSK '')
    
    cat <<-EOF
	config wifi-iface
	    option device $radio
	    option network vl$vid
	    option mode ap
	    option ssid "$ssid"
	    $(
	      if [ -z "$psk" ] ; then
		echo "option encryption none"
	      else
		echo "option encryption \"psk2\""
		echo "    option key \"$psk\""
	      fi
	    )

	EOF
  done
}

config_wifi() {
  if $WIFI ; then
    if [ -z "${WIFI_WCHAN:-}" ] ; then
      warn "Missing WIFI_WCHAN"
    else
      fixfile -N /etc/config/wireless <<-EOF
	config wifi-device radio0
	    option hwmode 11g
	    option path 'platform/ath9k'
	    option htmode HT20
	    option type mac80211
	    option channel $WIFI_WCHAN
	    option disabled 0

	$(config_wifi_radio radio0)
	EOF
      return 0
    fi
  fi
  fixfile -N /etc/config/wireless <<-EOF
	config wifi-device  radio0
	    option type     mac80211
	    option channel  11
	    option hwmode	11g
	    option path	'platform/ath9k'
	    option htmode	HT20
	    # REMOVE THIS LINE TO ENABLE WIFI:
	    option disabled 1
	EOF
}

vlan_ports() {
  local ports="5t" vlan="$1" i p_vlan
  local is_tagged
  if [ $vlan = $DEFAULT_VLAN ] ; then
    is_tagged=""
  else
    is_tagged="t"
  fi

  for i in $(seq 0 4)
  do
    p_vlan=$(get SWITCH_${i} "")
    [ -z "$p_vlan" ] && continue || :

    if [ x"$p_vlan" = x"trunk" ] ; then
      ports="$ports ${i}${is_tagged}"
    elif [ x"$p_vlan" = x"$vlan" ] ; then
      ports="$ports ${i}"
    fi
  done
  echo "$ports"
}

config_switch() {
  local swname=switch0
  
  cat <<-EOF
	config switch
	    option name "$swname"
	    option reset 1
	    option enable_vlan 1
	    option enable_vlan4k 1
	
	EOF

  local vnet vid port
  for vnet in $VLANS
  do
    vid=$(get ${vnet}_VLAN_ID)
    echo "# $vnet"
    echo "config switch_vlan"
    echo "    option device \"$swname\""
    echo "    option vlan $vid"
    echo "    option ports \"$(vlan_ports $vnet)\""
    echo ""
  done

  local def_vlan_id=$(get ${DEFAULT_VLAN}_VLAN_ID "")
  if [ -n "$def_vlan_id" ] ; then
    for port in $(seq 0 4)
    do
      vid=$(get SWITCH_${port} "")
      [ -z "$vid" ] && continue || :
      [ x"$vid" != x"trunk" ] && continue || :
      cat <<-EOF
	config switch_port
	    option port $port
	    option pvid $def_vlan_id

	EOF
    done
  fi
}
