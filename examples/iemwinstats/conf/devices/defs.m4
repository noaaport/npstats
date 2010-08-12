dnl
dnl $Id$
dnl
define(m4pool,
`lappend devices(devicelist) {
    deviceid "iemwinnet.$4pool"
    devicenumber $1
    devicetype "$2"
    export 1
    csvarchive 1
    displaystatus 1
    displaytemplate "$2.tml"
}
set devices(poller,iemwinnet.$4pool) "$2poll -p $3 $4";'
)dnl

define(m4pool_disable,
`
#
# pool $4 available
#
'
)dnl

define(m4pool_offline,
`
#
# pool $4 offline
#
'
)dnl

define(m4pool_wxmesg,
`
#
# pool $4 is wxmesg
#
'
)dnl
