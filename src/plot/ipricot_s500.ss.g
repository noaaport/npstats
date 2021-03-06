#
# $Id$
#
# gnuplot template for ipricot_s500.signal_strength
#

set gplot(script) {

    #set terminal png small xd0d0d0
    #set output "ss.png"
    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Signal strength (%)"
    set xlabel "Time gmt"
    set title "Signal strength (%) $gplot(deviceid)"

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
    set key outside

    set datafile separator ","

    plot [][60:100] '-' using 2:9 with lines title "Min",\
    '-' using 2:10 with lines title "Max"
    $gplot(data)
    e
    $gplot(data)

    quit
}
