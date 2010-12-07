#
# $Id: novra_s75.ss.g 19 2010-04-16 19:10:17Z nieves $
#
# gnuplot template for novra_s75.signal_strength
#

set gplot(script) {

    #set terminal png small xd0d0d0
    #set output "ss.png"
    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Signal strength (dbm)"
    set xlabel "Time gmt"
    set title "Signal strength (dbm) $gplot(deviceid)"

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

    plot [][] '-' using 2:13 with boxes title "Max", \
    '-' using 2:11 with boxes title "Min"
    $gplot(data)
    e
    $gplot(data)

    quit
}
