#
# $Id$
#
# gnuplot template for ayecka_sr1.crc_errors per channel (pid)
#

# These must be passed to npstatsplot via -D or defined here
#
# For the first channel (pid = 101)
#
# set gplot(_index) 12;     # index of column in data file (12 for pid=101)
# set gplot(_channel) 1;    # pid channel (1-5) or (101-105)

set gplot(script) {

    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Errors"
    set xlabel "Time gmt"
    set title "Crc Errors $gplot(_channel)"

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

    plot '-' using 2:$gplot(_index) notitle with lines
    $gplot(data)

    quit
}
