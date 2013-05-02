#
# $Id$
#
# gnuplot template for ayecka_sr1.ber
#

set gplot(script) {

    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Vber"
    set xlabel "Time gmt"
    # set title "Viterbi Bit Error Rate $gplot(deviceid)"
    set title "Viterbi Bit Error Rate"

    # set size 0.6,0.6
    set size $gplot(size)

    #set lmargin 8
    #set bmargin 4

    # time series specification for x axis, such as
    set xdata time
    # set timefmt "%Y%m%d%H%M%S"
    set timefmt "%s"
    set format x "%d\n%H"
    set logscale y 

    set style fill solid
    set boxwidth 0.5 relative
    set key outside

    set datafile separator ","

    plot [][1.0e-10:1.0e-03] '-' using 2:10 with boxes title "Max", \
    '-' using 2:9 with boxes title "Min"
    $gplot(data)
    e
    $gplot(data)

    quit
}
