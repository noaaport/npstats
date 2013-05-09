#!/bin/sh

#
# -Pu => allow underlines in names
# -Ou => Display UCD-style
#
snmpwalk -v 1 -c public -m ALL -M -mibs -Pu  ppg.uprrp.edu iso
