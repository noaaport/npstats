#
# $Id$
#
# gnuplot template for ayecka_sr1 crc_errors1 (from dvbs chipset)
# crcErrors1 - a counter of MPEGs failed CRC8 reported by DVBS2 chipset, on 
# entire transport stream
#

set gplot(script) {

    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Errors"
    set xlabel "Time gmt"
    set title "Crc Errors on entire transport"

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

    plot '-' using 2:15 notitle with boxes
    $gplot(data)

    quit
}
