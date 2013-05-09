#
# $Id$
#
# gnuplot template for ayecka_sr1 bad frames
#

set gplot(script) {

    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Frames"
    set xlabel "Time gmt"
    set title "Bad frames on entire transport"

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

    plot '-' using 2:16 notitle with boxes
    $gplot(data)

    quit
}
