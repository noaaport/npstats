#
# $Id$
#

# defaults (FreeBSD)
INCLUDE=".include"
Q='"'
PREFIX=usr/local

TCL_INCDIR="-I /usr/local/include/tcl8.6"
TCL_LIB="tcl86"
TCLSH=/usr/local/bin/tclsh8.6

LOCAL_INCDIR="-I /usr/local/include"
LOCAL_LIBDIR="-L /usr/local/lib"

CC=cc
CCWFLAGS="-Wall -Wextra"
INSTALL=install
SUFFIXRULES=".c.o:"

# excude options to tar
EXCLUDE="--exclude "

os=`uname`
[ $os = Linux ] && flavor=unknown
if [ -f /etc/fedora-release ]
then
    flavor=fedoracore
elif [ -f /etc/SuSE-release ] 
then
   flavor=opensuse
elif [ -f /etc/redhat-release ] 
then
   flavor=centos
elif [ -f /etc/debian_version ] 
then
   flavor=debian
   debian="0"
   ubuntu="0"
   if [ -f /etc/os-release ]
   then
	. /etc/os-release
	[ $ID = "debian" ] && debian=$VERSION_ID
        [ $ID = "ubuntu" ] && ubuntu=$VERSION_ID
   fi
fi

case $os in
    FreeBSD) 
        # use the defaults
	;;
    NetBSD)
	PREFIX=usr/pkg
        TCL_LIB="-ltcl84"
        TCL_INCDIR="-I /usr/pkg/include"
        TCLSH=/usr/pkg/bin/tclsh
        LOCAL_LIBDIR="-L /usr/pkg/lib"
	LOCAL_INCDIR="-I /usr/pkg/include"
	CCWFLAGS="-Wall -Wno-char-subscripts -fno-strict-aliasing"
        ;;
    Linux)
	INCLUDE=include
	Q=

	SUFFIXRULES="%.o: %.c"
	EXCLUDE="--exclude "

	TCL_INCDIR=
	TCL_LIB="tcl8.5"
	TCLSH=/usr/bin/tclsh8.5
	LOCAL_INCDIR=
	LOCAL_LIBDIR=

	# Override the defaults for flavor != fedoracore
    	if [ $flavor = opensuse ]
	then
	   continue
	elif [ $flavor = centos ]
	then
	   TCL_INCDIR=
	   TCL_LIB="tcl8.5"
	   TCLSH=/usr/bin/tclsh
	elif [ $flavor = debian ]
	then
	   # debian 7
	   TCL_INCDIR="-I /usr/include/tcl8.5"
	   TCL_LIB="tcl8.5"
	   TCLSH=/usr/bin/tclsh8.5
	   if [ $debian = "8" ]
	   then
		TCL_INCDIR="-I /usr/include/tcl8.6"
	   	TCL_LIB="tcl8.6"
	   	TCLSH=/usr/bin/tclsh8.6
	   elif [ $ubuntu = "14.04" ]
	   then
 	   	TCL_INCDIR="-I /usr/include/tcl8.6"
	   	TCL_LIB="tcl8.6"
	   	TCLSH=/usr/bin/tclsh8.6
	   fi
    	fi
     	;;
esac

configure_default () {

  makefile_out=Makefile
  [ $# -eq 1 ] && makefile_out=$1
  makefile_in=${makefile_out}.in

  sed \
      -e "/@include@/ s||$INCLUDE|" \
      -e "/@q@/ s||$Q|g" \
      -e "/@PREFIX@/ s||$PREFIX|" \
      -e "/@INSTALL@/ s||$INSTALL|" \
      -e "/@TCL_INCDIR@/ s||$TCL_INCDIR|" \
      -e "/@TCL_LIB@/ s||$TCL_LIB|" \
      -e "/@TCLSH@/ s||$TCLSH|" \
      -e "/@LOCAL_INCDIR@/ s||$LOCAL_INCDIR|" \
      -e "/@LOCAL_LIBDIR@/ s||$LOCAL_LIBDIR|" \
      -e "/@CC@/ s||$CC|" \
      -e "/@CCWFLAGS@/ s||$CCWFLAGS|" \
      -e "/@SUFFIXRULES@/ s||$SUFFIXRULES|" \
      -e "/@EXCLUDE@/ s||$EXCLUDE|" \
      $makefile_in > $makefile_out
}
