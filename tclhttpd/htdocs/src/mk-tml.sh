#!/bin/sh

include_dir="include"
templates_dir="templates"

[ $# -ne 1 ] && { echo "Needs one name"; exit 1; }
page=$1

sed -e "/@header@/r ${include_dir}/header.html" \
    -e "/@header@/d" \
    -e "/@menu@/r ${include_dir}/menu.html" \
    -e "/@menu@/d" \
    -e "/@body@/r ${page}.tml.body" \
    -e "/@body@/d" ${templates_dir}/template.tml.in
