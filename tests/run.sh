#!/bin/bash

if [ "$USER" != "root" ]; then
  echo "You have to be 'root'"
  exit 1
fi

set -e
cd `dirname $0`

INSTANCES=${1:-1}
JOBS=${2:-1}

if [ "$1" == "" ]; then
  (sleep 2; brctl addif or1k-br tap0; ip link set up dev tap0) &
  cat or1ksim-tcp.cfg | sed "s/TAP_DEVICE/tap0/" \
    | /usr/local/bin/sim --nosrv -f /dev/stdin ../linux/vmlinux
  exit 0
fi

echo "Starting ${INSTANCES} simulators .."

:> instances

for ID in $(seq 1 ${INSTANCES})
do
  echo "Starting instance $ID"
  (sleep 2; brctl addif or1k-br tap$ID; ip link set up dev tap$ID) &
  cat or1ksim-tcp.cfg | sed "s/TAP_DEVICE/tap$ID/" \
    | /usr/local/bin/sim --nosrv -f /dev/stdin ../linux/vmlinux &> /tmp/or1ksim-$ID.log &
done

# Find all instances
while [ $(arp -n | grep or1k-br | grep -v incomplete -c) -lt "${INSTANCES}" ]
do
  echo "Waiting on instances to come up .."
  sleep 3
done

arp -n | grep or1k-br | grep -v incomplete | cut -f 1 -d ' ' > instances.tmp

# Duplicate and randomize order to increase efficiency per simulator.
for i in $(seq 1 $JOBS)
do
  cat instances.tmp >> instances.dup
done

shuf instances.dup > instances

rm -f instances.tmp instances.dup

exit 0
