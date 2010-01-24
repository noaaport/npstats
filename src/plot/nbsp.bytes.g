#
# $Id$
#
# gnuplot template for device nbsp (bytes)
#

set gplot(script) {

    # set terminal png small xd0d0d0
    # set output "nbsp.png"

    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Bytes"
    set xlabel "Time gmt"
    set title "Bytes processed $gplot(deviceid)"

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

    plot '-' using 2:4 lc 2 with boxes notitle
    $gplot(data)

    quit
}
