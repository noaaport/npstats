#
# $Id$
#
# gnuplot template for ipricot_s500.temp
#

set gplot(script) {

    #set terminal png small xd0d0d0
    #set output "temp.png"
    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"
    set ylabel "Temperature"
    set xlabel "Time gmt"
    set title "Receiver Temperature $gplot(deviceid)"

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

    plot [][80:100] '-' using 2:13 with lines notitle
    $gplot(data)

    quit
}
