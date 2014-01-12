#!/bin/bash
set -e

GIT_BASE=${1?}
KERNEL="3.12.6"

echo "Running OpenRISC regression turnup on $HOST with repos @ $GIT_BASE"

sudo apt-get update
sudo apt-get install --yes screen git wget build-essential texinfo flex bison \
  libmpc-dev gawk bc expect nfs-kernel-server isc-dhcp-server bridge-utils \
  autogen

sudo service isc-dhcp-server stop || true

echo 'INTERFACES="or1k-br"' | sudo tee /etc/default/isc-dhcp-server
sudo tee /etc/dhcp/dhcpd.conf << _EOF_
default-lease-time 600;
max-lease-time 7200;

subnet 172.16.0.0 netmask 255.255.255.0 {
  range 172.16.0.10 172.16.0.100;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
  option routers 172.16.0.1;
}
_EOF_

sudo /sbin/brctl addbr or1k-br
sudo ip addr add 172.16.0.1/24 dev or1k-br
sudo ip link set up dev or1k-br

sudo service isc-dhcp-server start

sudo chown $USER.$USER /srv

mkdir -p /srv/compilers
mkdir -p /srv/build
sudo mount none -t tmpfs /srv/build

ssh-keygen -N '' -f ~/.ssh/or1ksim

echo "Cloning .."

cd /srv
git clone $GIT_BASE/or1k-devel.git

sudo tee /etc/exports << _EOF_
/srv/or1k-devel/initramfs 172.16.0.0/16(ro,async,no_root_squash,no_subtree_check)
/srv/or1k-devel           172.16.0.0/16(ro,async,no_subtree_check)
/srv/build                172.16.0.0/16(ro,async,no_subtree_check,fsid=1)
_EOF_
sudo service nfs-kernel-server restart

cd or1k-devel

echo $GIT_BASE/or1k-src.git \
     $GIT_BASE/or1k-gcc.git \
     $GIT_BASE/or1k-glibc.git \
     $GIT_BASE/or1k-linux.git \
     $GIT_BASE/or1ksim.git \
     https://github.com/openrisc/or1k-dejagnu \
     | xargs -n 1 -P 0 git clone

ln -sf or1k-linux linux

echo "Building .."
export PATH="$PATH:/srv/compilers/openrisc-devel/bin"

make linux
make root
make or1ksim
make dejagnu

cd tests
make simulators
echo "Waiting 30 s for the simulator instances to come up .."
sleep 30

echo "Creating SSH multiplexers .."
make ssh

echo "Testing .."
make test

echo "Testing done, halting machine"
halt
