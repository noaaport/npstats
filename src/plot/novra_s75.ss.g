#
# $Id$
#
# gnuplot template for dev_novra_s75.signal_strength
#

set gplot(script) {

    #set terminal png small xd0d0d0
    #set output "ss.png"
    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Signal strength"
    set xlabel "Time"
    set title "Signal strength $gplot(deviceid)"

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

    # set style fill solid
    # set boxwidth 0.5 relative

    set datafile separator ","

    plot '-' using 2:5 notitle with lines 2
    $gplot(data)

    quit
}
