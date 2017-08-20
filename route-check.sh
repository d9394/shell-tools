#!/bin/sh
TMPSTR=`nslookup baidu.com 202.96.134.33 | grep "^Address" | sed -n '2p' | awk '{print $3}'`
OLDIP=`cat /etc/hosts | grep baidu.com | awk '{print $1}'`
if [ -z "${OLDIP}" ]; then
  echo ${TMPSTR} baidu.com >> /etc/hosts
else
  if [ "${OLDIP}" != "${TMPSTR}" ]; then
    route del ${OLDIP}
    cat /etc/hosts | grep -v baidu.com > /tmp/hosts.tmp
    mv -f /tmp/hosts.tmp /etc/hosts
    echo ${TMPSTR} baidu.com >> /etc/hosts
  fi
  cat /etc/hosts
fi
ITEMGW=`netstat -rn | grep "^${TMPSTR}" | wc -l`
if [ "${ITEMGW}" -eq 0 ]; then
 route add ${TMPSTR} gateway ${OLDGW}
fi
