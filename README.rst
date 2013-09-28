Overview
========

**Npstats** is a system for monitoring the *NOAAPort* signal
with respect to signal levels and quality, performance
characteristics of the receivers and software processing systems
such as *Nbsp* and *Npemwin*. **Npstats** can collect data from a number
of devices from a number of sites, and send the data to a remote central server
for analysis, display and archival.

The **Npstats** binary package is configured to monitor the status
of the Novra S300 Noaaport receiver by default. Support for the Ayecka SR1
receiver was added in version 0.6. To monitor the Ayecka SR1 the
snmp package must be installed, or example in debian and freebsd,

    apt-get install snmp
    pkg_add -r net-snmp

Then execute the following::

    cd /usr/local/etc/npstats
    cp dist/devices.conf-ayecka defaults/devices.conf

and to switch back to the Novra S300::

    cp dist/devices.conf-novra defaults/devices.conf
