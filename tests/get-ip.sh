#!/bin/bash

set -e
cd $(dirname $0)

IP=$(head -n1 instances)
if [ -z "$IP" ]; then
  exit 1
fi

echo $IP

if [ "$1" == "--rotate" ]; then
  TMP=$(mktemp)
  cp instances $TMP
  tail -n +2 $TMP > instances
  rm $TMP
fi
