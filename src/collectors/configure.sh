#!/bin/sh

subdirs="lib
manager
qrunner
spooler
monitor"

for d in $subdirs
do
    cd $d
    ./configure.sh
    cd ..
done
