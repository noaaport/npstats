#
# $Id$
#
. ../../../configure.inc

# defaults (FreeBSD)
INCDIRS="$LOCAL_INCDIR $TCL_INCDIR"
LIBDIRS="$LOCAL_LIBDIR"
LIBS="$TCL_LIB -lpthread"

case $os in
    FreeBSD) 
        # use the defaults
	;;
    Linux)
	INCDIRS="$TCL_INCDIR"
	LIBDIRS=
	;;
esac
