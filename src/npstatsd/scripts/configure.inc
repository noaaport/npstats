#
# $Id$
#
. ../../../configure.inc

RCINIT=npstatsd.sh-freebsd

case $os in
    FreeBSD) 
    	;;
    NetBSD) 
	RCINIT=npstatsd.sh-netbsd
    	;;
    OpenBSD) 
	RCINIT=npstatsd.sh-generic
    	;;
    Linux)
	RCINIT=npstatsd.sh-${flavor}
    	;;
    Darwin)
	RCINIT=npstatsd.sh-macosx
	;;
esac
