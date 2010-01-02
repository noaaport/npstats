#
# $Id$
#
. ../../../configure.inc

RCINIT=npstatsd.sh-freebsd
HOURLYCONF=hourly-cleanup.conf-freebsd

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
	HOURLYCONF=hourly-cleanup.conf-generic
    	;;
    Darwin)
	RCINIT=npstatsd.sh-macosx
	;;
esac
