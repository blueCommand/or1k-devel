TARGET=or1k-linux-gnu
BUILDDIR=/srv/build
INSTANCES=4
JOBS=4
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
	# TODO(bluecmd): kill ssh instances

test-glibc:
	# TODO(blucmd): maybe we can use -j here to do things in parallel
	(export PATH="/srv/compilers/openrisc-devel/bin:${PATH}" && \
	 cd ${BUILDDIR}/build-or1k-glibc && \
		make check test-wrapper="/srv/or1k-devel/or1k-glibc/scripts/cross-test-ssh.sh $(shell ${SRCDIR}/get-ip.sh)")
