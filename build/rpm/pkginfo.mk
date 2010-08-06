#
# $Id$
#

# This is read by the (rpm) makefile to produce the <name>-<version>.spec
# file. The defaults are for FC, and the overrides are other flavors are below.
FLAVOR = $(shell ./flavor.sh)

package_build = 1
rpmroot = /usr/src/redhat

# empty variables will be filled by make
Summary = Noaaport and Emwin Statistics Tracking System
Name = ${name}
Version = ${version}
Release = ${package_build}
License = BSD
Group = Applications/Internet
Source = http://www.noaaport.net/software/${pkgsrc_name}/src/${pkgsrc_name}.tgz
BuildRoot = ${rpmroot}/BUILD/${pkgsrc_name}/build/rpm/pkg
Requires = tcl tcllib gnuplot

ifeq (${FLAVOR}, opensuse)
rpmroot = /usr/src/packages
endif
