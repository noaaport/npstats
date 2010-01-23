#
# $Id$
#
package ifneeded npstats::db 1.0 \
    [list source [file join $dir db.tcl]]

package ifneeded npstats::devices 1.0 \
    [list source [file join $dir devices.tcl]]

package ifneeded npstats::errx 1.0 \
    [list source [file join $dir errx.tcl]]

package ifneeded npstats::monitor 1.0 \
    [list source [file join $dir monitor.tcl]]

package ifneeded npstats::mscheduler 1.0 \
    [list source [file join $dir mscheduler.tcl]]

package ifneeded npstats::poll 1.0 \
    [list source [file join $dir poll.tcl]]

package ifneeded npstats::sftp 1.0 \
    [list source [file join $dir sftp.tcl]]

package ifneeded npstats::spooler 1.0 \
    [list source [file join $dir spooler.tcl]]

package ifneeded npstats::syslog 1.0 \
    [list source [file join $dir syslog.tcl]]
