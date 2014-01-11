#!/bin/bash

# SSH control master script
# This will keep a SSH session opened to the target at all times
# to prevent the need for doing the very slow key exchange multiple times.
#
# Kill the master by creating /tmp/stop

exec &> /dev/null
nohup ssh -o ControlMaster=yes 172.16.0.2 \
  'sh -c "rm -f /tmp/stop; while [ ! -f /tmp/stop ]; do sleep 60; done"' &

while [ ! -S /tmp/or1ksim ]
do
  sleep 1
done
