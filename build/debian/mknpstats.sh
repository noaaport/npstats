#!/bin/sh

name=npstats
tgzfile=${name}.tgz

rm -rf $name
tar -xzf $tgzfile

. $name/VERSION

cd $name
cp -R build/debian .
dpkg-buildpackage -rfakeroot
cp ../${name}_${version}*.deb build/debian
