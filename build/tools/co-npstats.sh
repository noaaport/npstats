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

# Override tag with the cmd line argument (e.g., "nbsp-2.1.1r")
[ $# -ne 0 ] && tag=tags/$1

svn co ${mastersite}/${project}/$tag ${project}
