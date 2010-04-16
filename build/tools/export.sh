#!/bin/sh
#
# $Id$
#

masterhost="http://svn.1-loop.net"
masterrepo="npstatsrepo"
mastersite=${masterhost}/${masterrepo}

# read name and version
. ../../VERSION

tmpdir=tmp
rm -r -f $tmpdir
mkdir $tmpdir

cd $tmpdir
svn export ${mastersite}/${name}/trunk ${name}-${version}

tar -czf ../${name}-${version}.tgz ${name}-${version}

cd ..
rm -rf $tmpdir
