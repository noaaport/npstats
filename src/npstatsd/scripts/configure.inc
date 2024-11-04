#
# $Id$
#
. ../../../configure.inc

RCINIT=npstatsd.sh-freebsd
RCFPATH=/usr/local/etc/rc.d/npstatsd
RCCONF=
HOURLYCONF=hourly-cleanup.conf-freebsd
SYSTEMDCONF=

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
	RCFPATH=/etc/init.d/npstatsd
	HOURLYCONF=hourly-cleanup.conf-generic
	SYSTEMDCONF=npstats.service-generic
	[ $flavor = debian ] && RCCONF=npstatsd.sh.conf-debian
    	;;
    Darwin)
	RCINIT=npstatsd.sh-macosx
	;;
esac
