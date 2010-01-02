#!/bin/sh
#
# $Id$
#

project=npstats
masterhost="http://svn.1-loop.net"
masterrepo="npstatsrepo"
mastersite=${masterhost}/${masterrepo}
##
## Your googlecode.com password: bk9bF8Vj6aU4
##

# read name and version
. ../../VERSION

tmpdir=tmp
rm -r -f $tmpdir
mkdir $tmpdir

cd $tmpdir
# svn export http://${name}.googlecode.com/svn/trunk ${name}-${version}
svn export ${mastersite}/${project}/trunk ${name}-${version}

tar -czf ../${name}-${version}.tgz ${name}-${version}

cd ..
rm -rf $tmpdir
