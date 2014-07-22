TARGET=or1k-linux-gnu
BUILDDIR=/srv/build
INSTANCES=1
JOBS=1
PARALLEL=$(shell echo ${INSTANCES} \* ${JOBS} | bc)
SRCDIR=${PWD}

.PHONY: simulators ssh test

simulators:
	sudo ./run.sh ${INSTANCES} ${JOBS}

ssh:
	./ssh.sh

test-gcc:
	ln -sf /srv/compilers/openrisc-devel/bin/${TARGET}-gcc /srv/compilers/openrisc-devel/bin/gcc
	ln -sf /srv/compilers/openrisc-devel/bin/${TARGET}-g++ /srv/compilers/openrisc-devel/bin/g++
	(export PATH="/srv/compilers/openrisc-devel/bin:${PATH}" && \
	 cd ${BUILDDIR}/build-or1k-gcc && \
		 make -j${PARALLEL} check-c RUNTESTFLAGS="--target_board=or1k-linux-sim")
	cp -v /srv/build/build-or1k-gcc/gcc/testsuite/gcc/gcc.log /tmp/
	cp -v /srv/build/build-or1k-gcc/gcc/testsuite/gcc/gcc.sum /tmp/
	./create-fail-log /tmp/gcc.log > /tmp/gcc.fail
	gsutil cp /tmp/gcc.* gs://bluecmd-openrisc/gcc/$(shell date +'%Y-%m-%d_%H:%M')/

test-glibc:
	# TODO(blucmd): maybe we can use -j here to do things in parallel
	(export PATH="/srv/compilers/openrisc-devel/bin:${PATH}" && \
	 cd ${BUILDDIR}/build-or1k-glibc && \
		make check test-wrapper="/srv/or1k-devel/or1k-glibc/scripts/cross-test-ssh.sh $(shell ${SRCDIR}/get-ip.sh)")
