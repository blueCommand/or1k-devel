#!/bin/bash
set -e

GIT_BASE=${1?}
KERNEL="3.12.6"

echo "Running OpenRISC regression turnup on $HOST with repos @ $GIT_BASE"

apt-get update
apt-get install --yes screen git wget build-essential texinfo flex bison \
  libmpc-dev gawk bc
mkdir -p ~/work
cd ~/work

mkdir -p /srv/compilers
export PATH="$PATH:/srv/compilers/openrisc-devel/bin"

echo "Cloning .."

git clone $GIT_BASE/or1k-devel.git &
wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-$KERNEL.tar.xz
wait

cd or1k-devel

tar -xf ../linux-$KERNEL.tar.xz &
echo $GIT_BASE/or1k-src.git \
     $GIT_BASE/or1k-gcc.git \
     $GIT_BASE/or1k-glibc.git \
     | xargs -n 1 -P 0 git clone
wait

ln -sf linux-$KERNEL linux

echo "Building .."
make


echo "Testing .."

echo "Testing done, halting machine"
halt
