#
# $Id$
#
# gnuplot template for qstate
#

set gplot(script) {

    #set terminal png small xd0d0d0
    #set output "qstate.png"
    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "Queue size"
    set xlabel "Time gmt"
    set title "Nbsp queue sizes $gplot(deviceid)"

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

    plot '-' using 2:3 with boxes title "Processor", \
    '-' using 2:4 with boxes title "Filter", \
    '-' using 2:5 with boxes title "Server"
    $gplot(data)
    e
    $gplot(data)
    e
    $gplot(data)

    quit
}
