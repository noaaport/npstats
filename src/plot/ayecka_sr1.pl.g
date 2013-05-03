#
# $Id$
#
# gnuplot template for ayecka_sr1.power_level
#

# Calculate the limits
set gplot(_ymin) [lindex [npstatsplot_minmax $gplot(data) 5] 0];
set gplot(_ymax) [lindex [npstatsplot_minmax $gplot(data) 6] 1];
set gplot(_ymin) [expr $gplot(_ymin) - 1];
set gplot(_ymax) [expr $gplot(_ymax) + 1];
#
# In case that the data is represented in float (e.g., 43.0 instead of 43)
# we use the above instead of
#
# incr gplot(_ymin) -1;
# incr gplot(_ymax) 1;
#

set gplot(script) {

    #set terminal png small xd0d0d0
    #set output "ss.png"
    set terminal $gplot(fmt) $gplot(fmtoptions)
    set output "$gplot(output)"

    set ylabel "dbm"
    set xlabel "Time gmt"
    # set title "Signal strength (dbm) $gplot(deviceid)"
    set title "Power level"

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

    plot [][$gplot(_ymin):$gplot(_ymax)] \
    '-' using 2:5 with lines linewidth 2 title "Min",\
    '-' using 2:6 with lines linewidth 2 title "Max"
    $gplot(data)
    e
    $gplot(data)

    quit
}
