#!/bin/bash

set -e

PROJECT="bluecmd0"
NAME="openrisc-regression1"
ZONE="europe-west1-b"
MACHINE="n1-highcpu-8"
GIT_BASE="https://github.com/bluecmd"

eval $(ssh-agent)
ssh-add ~/.ssh/google_compute_engine

gcutil addinstance \
  --service_version="v1" \
  --project="$PROJECT" \
  "$NAME" \
  --zone="$ZONE" \
  --machine_type="$MACHINE" \
  --network=default \
  --external_ip_address=ephemeral \
  --image="https://www.googleapis.com/compute/v1/projects/debian-cloud/global/images/debian-7-wheezy-v20131120" \
  --persistent_boot_disk=true \
  --noautomatic_restart \
  --on_host_maintenance=migrate \
  --wait_until_running

echo "Waiting 30 seconds for sshd to start"
sleep 30

gcutil push "$NAME" turnup.sh /tmp
gcutil ssh "$NAME" sudo /tmp/turnup.sh "$GIT_BASE"


