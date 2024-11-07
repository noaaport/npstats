#!/bin/sh

subdirs="npstatsd
collectors
plot
scheduler
pollers/nbsp
pollers/inbsp
pollers/inpemwin
pollers/sys
pollers/novra
pollers/ipricot
pollers/ayecka"

for d in $subdirs
do
    (cd $d; ./configure.sh)
done
