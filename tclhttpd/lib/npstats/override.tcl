#
# $Id$
#
# Here functions are functions that override some of the functions
# in dist:
#
# utils/Stderr
# log/Log_SetFile
# httpd/HttpdCloseP

#
# Provide a version of Sdterr using syslog
# (original is in utils.c)
#
rename Stderr Stderr.orig
proc Stderr {string} {

    global Config

    Stderr.orig $string

    if {$Config(syslog) == 1} {
	exec logger -t $Config(syslogident) $string
    }
}

#
# Eliminate compressing of the logfile in the background, which was
# leaving a defunct (gzip) process lying around until the next rotation.
# (original function is in log.tcl)
#
rename Log_SetFile Log_SetFile.orig
proc Log_SetFile {{basename {}}} {
    global Log
    if {[string length $basename]} {
	set Log(log) $basename
    }
    if {![info exists Log(log)]} {
	catch {close $Log(log_fd)}
	catch {close $Log(error_fd)}
	catch {close $Log(debug_fd)}
	return
    }
    catch {Counter_CheckPoint} 		;# Save counter data

    # set after event to switch files after midnight
    set now [clock seconds]
    set next [expr {([clock scan 23:59:59 -base $now] -$now + 1000) * 1000}]
    after cancel Log_SetFile
    after $next Log_SetFile

    # Set the log file and error file.
    # In the original, log files rotate, error files don't.
    # In nsbp both rotate.

    set Log(log_file) $Log(log)[clock format $now -format %y.%m.%d]
    catch {close $Log(log_fd)}

    # Create log directory, if neccesary, then open the log file
    catch {file mkdir [file dirname $Log(log_file)]}
    if {[catch {set Log(log_fd) [open $Log(log_file) a]} err]} {
	 Stderr $err
    }

    set error_file ""
    append error_file $Log(log_file) ".error";
    catch {close $Log(error_fd)}
    if {[catch {set Log(error_fd) [open $error_file a]} err]} {
	Stderr $err
    }

    # This debug log gets reset daily
    catch {close $Log(debug_fd)}
    if {[info exists Log(debug_file)] && [file exists $Log(debug_file)]} {
	catch {file rename -force $Log(debug_file) $Log(debug_file).old}
    }

    if {[info exist Log(debug_log)] && $Log(debug_log)} {
	set Log(debug_file) $Log(log)debug
	if {[catch {set Log(debug_fd) [open $Log(debug_file) w]} err]} {
	    Stderr $err
	}
    }
}

#
# With tls, this function gives the error explained in the file
# dev-notes/data_version-error.txt. The change is the line
#
#     } elseif {$data(version) >= 1.1} {
#
# that we rreplace by
#
# } elseif {[info exists data(version)] && ($data(version) >= 1.1)}
#
# The original is in httpd.tcl
#
rename HttpdCloseP HttpdCloseP.orig
proc HttpdCloseP {sock} {
    upvar #0 Httpd$sock data

    if {[info exists data(mime,connection)]} {
	if {[string tolower $data(mime,connection)] == "keep-alive"} {
	    Count keepalive
	    set close 0
	} else {
	    Count connclose
	    set close 1
	}
    } elseif {[info exists data(mime,proxy-connection)]} {
	if {[string tolower $data(mime,proxy-connection)] == "keep-alive"} {
	    Count keepalive
	    set close 0
	} else {
	    Count connclose
	    set close 1
	}
    } elseif {[info exists data(version)] && ($data(version) >= 1.1)} {
	Count http1.1
    	set close 0
    } else {
	# HTTP/1.0
	Count http1.0
	set close 1
    }
    if {[info exists data(left)] && [expr {$data(left) == 0}]} {
	# Exceeded transactions per connection
	Count noneleft
    	set close 1
    }
    return $close
}
