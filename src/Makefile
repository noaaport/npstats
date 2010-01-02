#
# Copyright (c) 2009 Jose F Nieves
#
# See LICENSE
#
# $Id$
#

SUBDIRS = npstatsd collectors plot \
	pollers/nbsp \
	pollers/sys \
	pollers/novra

all:
	for dir in ${SUBDIRS}; do \
	(cd $$dir; ${MAKE}) \
	done

install:
	for dir in ${SUBDIRS}; do \
	(cd $$dir; ${MAKE} install) \
	done

clean:
	rm -f *~
	for dir in ${SUBDIRS}; do \
	(cd $$dir; ${MAKE} clean) \
	done
