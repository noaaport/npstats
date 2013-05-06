#
# $Id$
#
# gnuplot template for ayecka_sr1 "Es/No"
#

set gplot(script) {

    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "dbm"
    set xlabel "Time gmt"
    # set title "Es/No $gplot(deviceid)"
    set title "Es/No"

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

    plot '-' using 2:11 with lines title "Min", \
    '-' using 2:12 with lines title "Max"
    $gplot(data)
    e
    $gplot(data)

    quit
}
