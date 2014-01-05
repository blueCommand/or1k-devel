#!/bin/bash

if [ "$USER" != "root" ]; then
  sudo $0 $*
  exit $?
fi

cd `dirname $0`
echo "Starting simulator .."
screen -dmS openrisc-sim /usr/local/bin/sim -f or1ksim-tcp.cfg vmlinux
sleep 2
echo "Configuring network .."
sudo ip link set up dev tap0
sudo ip addr add 192.168.255.201/24 dev tap0

echo "Done"
