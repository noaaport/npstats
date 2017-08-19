#!/bin/sh

name=npstats

DPKG_COLORS="never"
export DPKG_COLORS

cd $name/build/debian
./mk.sh
