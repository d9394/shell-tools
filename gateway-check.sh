#!/bin/sh
OLDGW='192.168.1.1'
ITEMGW=`netstat -rn | grep '^202.96.134.33' | wc -l`
if [ "${ITEMGW}" -eq 0 ]; then
  route add 202.96.134.33 gw ${OLDGW}
fi
