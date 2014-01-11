#!/bin/sh

ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -l root 172.16.0.2 $*
