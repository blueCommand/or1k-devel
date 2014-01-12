#!/bin/bash

# SSH control master script
# This will keep a SSH session opened to the target at all times
# to prevent the need for doing the very slow key exchange multiple times.
#
# Kill the master by creating /tmp/stop

exec &> /dev/null

# I can't think of a better way than doing this :(
:> ~/.ssh/config

for IP in $(cat instances | sort -u)
do
  cat ssh_config | sed "s/OR1K_IP/$IP/g" >> ~/.ssh/config
  nohup ssh -o ControlMaster=yes $IP \
    'sh -c "rm -f /tmp/stop; while [ ! -f /tmp/stop ]; do sleep 60; done"' &
done

for IP in $(cat instances | sort -u)
do
  while [ ! -S /tmp/or1ksim-$IP ]
  do
    sleep 1
  done
done
