#!/bin/sh

type="dev_novra_s75"
parameters="vber ss errors"

for p in $parameters
do
    for id in 1001 1004
    do
      echo -n "${type}.${id}.${p}.png ..."
	./npstatsdbplot.tcl -s "0.8,0.6" \
	    -o ${type}.${id}.${p}.png $type $id ${type}.${p}.g
	echo done
    done
done
