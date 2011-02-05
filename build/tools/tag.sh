#!/bin/sh

. ../../VERSION

masterrepo="npstatsrepo"
#
project=$name
tag=tags/${name}-${version}
#
#masterhost="http://svn.1-loop.net"
masterhost="svn+ssh://jfnieves@svn.1-loop.net/home/jfnieves/svn"
#
## mastersite="svn+ssh://diablo/home/svn"
mastersite=${masterhost}/${masterrepo}

[ $# -ne 0 ] && tag=tags/$1

cd ../../../
svn copy $project $mastersite/$project/$tag
