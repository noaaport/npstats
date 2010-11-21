#!/bin/sh

. ../../VERSION

cd ..
cp -R debian ..

cd ..
dpkg-buildpackage -rfakeroot
cp ../${name}_${version}*.deb debian

cd build/debian
./ckplist.sh ${name}_${version}*.deb
