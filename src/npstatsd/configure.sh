#!/bin/sh

subdirs="src conf scripts"

for d in $subdirs
do
    cd $d
    ./configure.sh
    cd ..
done
