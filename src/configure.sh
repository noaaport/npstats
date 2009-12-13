#!/bin/sh

subdirs="npstatsd
collectors
plot
pollers/nbsp
pollers/sys"

for d in $subdirs
do
    (cd $d; ./configure.sh)
done
