#
# $Id$
#
# gnuplot template for ipricot_s500.sn (Eb/No)
#

set gplot(script) {

    #set terminal png small xd0d0d0
    #set output "sn.png"
    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Eb/No"
    set xlabel "Time gmt"
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

    set style fill solid
    set boxwidth 0.5 relative

    set datafile separator ","

    plot [][5:12] '-' using 2:5 with boxes title "Max", \
    '-' using 2:4 with boxes title "Min"
    $gplot(data)
    e
    $gplot(data)

    quit
}
