dnl
dnl $Id$
dnl
define(m4pool,
`lappend devices(devicelist) {
    deviceid "iemwinnet.$3pool"
    devicenumber $1
    devicetype "$2"
    export 1
    csvarchive 1
    displaystatus 1
    displaytemplate "$2.tml"
}
set devices(poller,iemwinnet.$3pool) "$2poll $3";'
)dnl

define(m4pool_disable,
`
#
# pool $3 available
#
'
)dnl

define(m4pool_offline,
`
#
# pool $3 offline
#
'
)dnl

define(m4pool_wxmesg,
`
#
# pool $3 is wxmesg
#
'
)dnl
