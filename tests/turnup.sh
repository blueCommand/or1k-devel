#!/bin/bash
set -e

GIT_BASE=${1?}
KERNEL="3.12.6"

echo "Running OpenRISC regression turnup on $HOST with repos @ $GIT_BASE"

sudo apt-get update
sudo apt-get install --yes screen git wget build-essential texinfo flex bison \
  libmpc-dev gawk bc expect

sudo chown $USER.$USER /srv

mkdir -p /srv/compilers
mkdir -p /srv/build
sudo mount none -t tmpfs /srv/build

echo "Cloning .."

git clone $GIT_BASE/or1k-devel.git

cd or1k-devel

echo $GIT_BASE/or1k-src.git \
     $GIT_BASE/or1k-gcc.git \
     $GIT_BASE/or1k-glibc.git \
     $GIT_BASE/or1k-linux.git \
     https://github.com/openrisc/or1ksim \
     https://github.com/openrisc/or1k-dejagnu \
     | xargs -n 1 -P 0 git clone

ln -sf or1k-linux linux

echo "Building .."
export PATH="$PATH:/srv/compilers/openrisc-devel/bin"

ssh-keygen -N '' -f ~/.ssh/or1ksim

make linux
make root
make or1ksim
make dejagnu

echo "Testing .."
cd tests
mkdir -p ~/.ssh
cat ssh_config >> ~/.ssh/config
./run.sh &> /tmp/simulator.log &
make test

echo "Testing done, halting machine"
halt
