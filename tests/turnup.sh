#!/bin/bash
set -e

GIT_BASE=${1?}

echo "Running OpenRISC regression turnup on $HOST with repos @ $GIT_BASE"

sudo apt-get update
sudo apt-get install --yes screen git wget build-essential texinfo flex bison \
  libmpc-dev gawk bc expect isc-dhcp-server bridge-utils \
  autogen dejagnu
sudo apt-get build-dep qemu

sudo service isc-dhcp-server stop || true

echo 'INTERFACES="buildbot-br"' | sudo tee /etc/default/isc-dhcp-server
sudo tee /etc/dhcp/dhcpd.conf << _EOF_
default-lease-time 600;
max-lease-time 7200;

subnet 172.16.0.0 netmask 255.255.255.0 {
  range 172.16.0.10 172.16.0.100;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
  option routers 172.16.0.1;
}
_EOF_

sudo /sbin/brctl addbr buildbot-br
sudo ip addr add 172.16.0.1/24 dev buildbot-br
sudo ip link set up dev buildbot-br

sudo service isc-dhcp-server start

sudo chown $USER.$USER /srv

mkdir -p /srv/compilers
mkdir -p /srv/build
sudo mount none -t tmpfs /srv/build

ssh-keygen -N '' -f ~/.ssh/id_rsa

echo "Cloning .."

cd /srv
git clone $GIT_BASE/or1k-devel.git

cd or1k-devel

echo $GIT_BASE/binutils-gdb.git \
     $GIT_BASE/or1k-gcc.git \
     $GIT_BASE/or1k-glibc.git \
     $GIT_BASE/or1k-linux.git \
     $GIT_BASE/or1k-qemu.git \
     https://github.com/openrisc/or1k-dejagnu \
     | xargs -n 1 -P 0 git clone

ln -sf or1k-linux linux

echo "Building .."
export PATH="$PATH:/srv/compilers/openrisc-devel/bin"

(cd linux; git checkout smp)

make linux
make qemu

qemu-img create -f raw /srv/build/root.img 1G
/sbin/mkfs.ext4 -F /srv/build/root.img

sudo mount -o loop /srv/build/root.img initramfs/
sudo chown bluecmd.bluecmd initramfs/
git checkout initramfs/

make root
sudo cp tests/or1k-linux-sim.exp /usr/share/dejagnu/baseboards

echo "Starting simulator .."
sudo screen -dmS qemu-sim tests/qemu-system /srv/build/root.img

echo "Waiting for simulator .."
sleep 10

cd tests
sudo arp -n | grep buildbot-br | grep -v incomplete \
  | cut -f 1 -d ' ' > instances

echo "Testing .."
make test-gcc
#
#echo "Testing done, halting machine"
#halt
