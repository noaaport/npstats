#!/bin/sh

project=npstats
#
masterhost="http://svn.1-loop.net"
masterrepo="npstatsrepo"
#
mastersite=${masterhost}/${masterrepo}

svn co ${mastersite}/${project}/trunk ${project}
