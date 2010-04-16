#!/bin/sh

subdirs="npstatsd
collectors
plot
pollers/nbsp
pollers/sys
pollers/novra
pollers/ipricot"

for d in $subdirs
do
    (cd $d; ./configure.sh)
done
