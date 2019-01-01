#!/bin/sh
#
# Manage installed software
#

# Install macros
OPKG_UPDATED="no"
USING_SWINST=false
xpkg=opkg

# Figure out what pkgs weere installed later (not part of SquashFS image)
swinst_init() {
  USING_SWINST=true
  OPKG_INSTALLED=$(
    $xpkg list-installed | (while read pkg junk
	do
	  status=$($xpkg status $pkg | grep 'Status:' | sed 's/^Status: //')
	  if (echo $status | grep -q 'user') ; then # user installed
	    # OK determine if it was installed by us or it is in the 
	    # SquashFS image...
	    In_ROM=no
	    Has_Files=no
	    for file in $($xpkg files $pkg | (read hdr; cat))
	    do
	      Has_Files=yes
	      if [ -f /rom$file ] ; then
		In_ROM=yes
		break
	      fi
	    done
	    if [ $Has_Files = no ] ; then
	      [ -f /rom/usr/lib/opkg/info/$pkg.list ] && continue || :
	    fi
	    [ $In_ROM = no ] && echo $pkg || :
	  fi
	done)
  )
}

swinst() {
  if ! $USING_SWINST ; then
    swinst_init
  fi
  
  local sw
  for sw in "$@"
  do
    # Software was requested...
    eval $(mkid RSW_${sw})=${sw}

    local stat=$($xpkg status $sw)
    [ -z "$stat" ] || continue
    # Will need to install this
    if [ $OPKG_UPDATED = "no" ] ; then
      $xpkg update
      OPKG_UPDATED="yes"
    fi
    $xpkg install $sw
  done
}

swinst_cleanup() {
  if ! $USING_SWINST ; then
    # Not using SWINST...
    return
  fi
  local sw
  for sw in ${OPKG_INSTALLED}
  do
    eval local req=\$$(mkid RSW_${sw})
    if [ -z "$req" ] ; then
      # Software was not requested... can uninstalll
      $xpkg remove --autoremove $sw
    fi
  done

  if [ $OPKG_UPDATED = "yes" ] ; then
    rm -rf /tmp/opkg-lists
  fi
}

