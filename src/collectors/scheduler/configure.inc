#
# $Id$
#
. ../../../configure.inc

SCHEDCONF=scheduler.conf

case $os in
    FreeBSD) 
        # use the defaults
	;;
    OpenBSD) 
        # use the defaults
	;;
    Linux)       
	;;
    Darwin)
	# use the defaults
	;;
esac
