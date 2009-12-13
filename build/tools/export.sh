#!/bin/sh
#
# $Id$
#

##
## Your googlecode.com password: bk9bF8Vj6aU4
##
tmpdir=tmp

# read name and version
. ../../VERSION

rm -r -f $tmpdir
mkdir $tmpdir

cd $tmpdir
svn export http://${name}.googlecode.com/svn/trunk ${name}-${version}

tar -czf ../${name}-${version}.tgz ${name}-${version}

cd ..
rm -rf $tmpdir
