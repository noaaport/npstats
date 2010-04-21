#
# $Id$
#
. ../../../configure.inc

RCINIT=npstatsd.sh-freebsd
RCCONF=
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
	[ $flavor = debian ] && RCCONF=npstatsd.sh.conf-debian
    	;;
    Darwin)
	RCINIT=npstatsd.sh-macosx
	;;
esac
