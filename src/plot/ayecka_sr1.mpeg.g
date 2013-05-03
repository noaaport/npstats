#
# $Id$
#
# gnuplot template for ayecka_sr1.mpeg_packets
#

# Uses
#
# set gplot(_index) 17;     # index of column in data file (17 for pid=101)
# set gplot(_channel) 1;    # pid channel (1-5) or (101-105)
#
# (see the crc template)

set gplot(script) {

    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Num packets"
    set xlabel "Time gmt"
    set title "MPEG Packets Accepted $gplot(_channel)"

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
