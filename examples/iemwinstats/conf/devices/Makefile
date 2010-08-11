#
# $Id$
#

SOURCES = defs.m4 devices.m4 pool.m4
TARGET = devices.conf
INSTALLDIR = /usr/local/etc/npstats/site

EXSOURCES = defs.m4 devices.m4 pool-ex.m4
EXTARGET = devices.conf-ex

all: ${TARGET}

${TARGET}: ${SOURCES}
	m4 devices.m4 pool.m4 > ${TARGET}

install: all
	install -m 0644 ${TARGET} ${INSTALLDIR}

example: ${EXTARGET}

${EXTARGET}: ${EXSOURCES}
	m4 devices.m4 pool-ex.m4 > ${EXTARGET}

clean:
	rm -f *~ ${TARGET} ${EXTARGET}
 