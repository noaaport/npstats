#!/bin/sh

branchname=npstats

cd ${branchname}/build/rpm
make clean
make package
