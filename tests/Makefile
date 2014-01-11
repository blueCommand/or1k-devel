TARGET=or1k-linux-gnu
BUILDDIR=/srv/build

test:
	ln -sf /srv/compilers/openrisc-devel/bin/${TARGET}-gcc /srv/compilers/openrisc-devel/bin/gcc
	ln -sf /srv/compilers/openrisc-devel/bin/${TARGET}-g++ /srv/compilers/openrisc-devel/bin/g++
	./ssh.sh
	(export PATH="/srv/compilers/openrisc-devel/bin:${PATH}" && \
	 cd ${BUILDDIR}/build-or1k-gcc && \
	 make check-c check-c++ RUNTESTFLAGS="execute.exp --verbose --target_board=or1k-linux-sim --target_triplet=or1k-unknown-linux-gnu")
	ssh 172.16.0.2 touch /tmp/stop
