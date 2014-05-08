#!/bin/sh

branchname=npstats

cd ../../..
. ./${branchname}/VERSION

rm -rf ${name}-${version}
cp -R $branchname ${name}-${version}

cd ${name}-${version}
(cd build/debian; ./mk-control.sh)
rm -rf debian
cp -R build/debian .
dpkg-buildpackage -rfakeroot -uc -us
cp ../${name}_${version}*.deb build/debian

cd build/debian
./ckplist.sh ${name}_${version}*.deb
