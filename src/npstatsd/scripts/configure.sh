#!/bin/sh

. ./configure.inc

sed \
    -e "/@include@/ s||$INCLUDE|" \
    -e "/@q@/ s||$Q|g" \
    -e "/@INSTALL@/ s||$INSTALL|" \
    -e "/@TCLSH@/ s||$TCLSH|" \
    -e "/@RCINIT@/s||$RCINIT|" \
    -e "/@RCFPATH@/s||$RCFPATH|" \
    -e "/@RCCONF@/s||$RCCONF|" \
    -e "/@HOURLYCONF@/s||$HOURLYCONF|" \
    -e "/@SYSTEMDCONF@/s||$SYSTEMDCONF|" \
    Makefile.in > Makefile
