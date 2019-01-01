#!/bin/sh
#
# Manage script installs
#
SCRIPTS_SOURCE=$(cd $(dirname $0) && pwd)/
SCRIPTS_TARGETS="/bin /sbin /usr/sbin /usr/bin"
SCRIPTS_INSTALLED=""

script_install() {
  local target="/bin"
  while [ $# -gt 0 ]
  do
    case "$1" in
    --target=*)
      target=${1#--target=}
      ;;
    *)
      break
      ;;
    esac
    shift
  done

  local i j k
  for i in "$@"
  do
    if [ ! -x "$SCRIPTS_SOURCE$i" ] ; then
      continue
    fi
    j=$(basename "$i")
    SCRIPTS_INSTALLED="$SCRIPTS_INSTALLED $target/$j"
    if [ -L "$target/$j" ] ; then
      k=$(readlink "$target/$j")
      if [ "$SCRIPTS_SOURCE$i" = "$k" ] ; then
	# No change...
	continue
      fi
      echo "Removing old link $target/$j"
      rm -f "$target/$j"
    elif [ -d "$target/$j" ] ; then
      # Invalid target destination...
      echo "Invalid target $target for $i"
      continue
    elif [ -e "$target/$j" ] ; then
      echo "Removing old content $target/$j"
      rm -f "$target/$j"
    fi
    echo "Linking $SCRIPTS_SOURCE$i to $target/$j"
    ln -s "$SCRIPTS_SOURCE$i" "$target/$j"
  done
}

script_cleanup() {
  local dir ln=$(expr length "$SCRIPTS_SOURCE") i j k
  for dir in $SCRIPTS_TARGETS
  do
    ls -l "$dir" | while read s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11
    do
      [ -z "$s11" ] && continue || :
      [ -z "$s10" ] && continue || :
      [ "$(expr substr "$s11" 1 $ln)" != "$SCRIPTS_SOURCE" ] && continue || :
      for i in $SCRIPTS_INSTALLED  ///not/found///
      do
	if [ "$i" = "$dir/$s9" ] ; then
	  break
	fi
      done
      if [ "$i" = "///not/found///" ] ; then
	echo "Removing $dir/$s9"
	rm -f "$dir/$s9"
      fi
    done
  done
}


