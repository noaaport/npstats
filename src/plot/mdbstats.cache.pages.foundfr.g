#
# $Id$
#
# gnuplot template for device mdbstats (cache.pages.foundfr)
#

set gplot(script) {

    # set terminal png small xd0d0d0
    # set output "nbsp.png"

    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Percent"
    set xlabel "Time gmt"
    set title "Percent of pages found in the cache\n$gplot(deviceid)"

    # set size 0.6,0.6
    set size $gplot(size)

    #set lmargin 8
    #set bmargin 4

    # time series specification for x axis, such as
    set xdata time
    # set timefmt "%Y%m%d%H%M%S"
    set timefmt "%s"
    set format x "%d\n%H"
    # set logscale y

    set style fill solid
    set boxwidth 0.5 relative

    set datafile separator ","

    plot '-' using 2:5 lc 2 with boxes notitle
    $gplot(data)

    quit
}
