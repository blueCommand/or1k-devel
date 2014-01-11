#!/bin/bash

if [ "$USER" != "root" ]; then
  sudo $0 $*
  exit $?
fi

cd `dirname $0`
echo "Starting simulator .."


(sleep 2; ip link set up dev tap0; ip addr add 172.16.0.1/24 dev tap0) &
/usr/local/bin/sim -f or1ksim-tcp.cfg ../linux/vmlinux
