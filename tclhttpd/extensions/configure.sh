#!/bin/sh

config_dirs=

for d in $config_dirs
do
    cd $d
    ./configure.sh
    cd ..
done
