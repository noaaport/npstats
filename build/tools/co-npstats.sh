#!/bin/sh

project=npstats
#
#masterhost="http://svn.1-loop.net"
masterhost="svn+ssh://jfnieves@svn.1-loop.net/home/jfnieves/svn"
#
masterrepo="npstatsrepo"
tag=trunk
#
mastersite=${masterhost}/${masterrepo}

# Override tag with the cmd line argument ("tags/nbsp-2.0.r1")
[ $# -ne 0 ] && tag=$1

svn co ${mastersite}/${project}/$tag ${project}
