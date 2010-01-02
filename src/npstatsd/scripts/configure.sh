#!/bin/sh

. configure.inc

sed \
    -e "/@include@/ s||$INCLUDE|" \
    -e "/@q@/ s||$Q|g" \
    -e "/@INSTALL@/ s||$INSTALL|" \
    -e "/@TCLSH@/ s||$TCLSH|" \
    -e "/@RCINIT@/s||$RCINIT|" \
    -e "/@HOURLYCONF@/s||$HOURLYCONF|" \
    Makefile.in > Makefile
