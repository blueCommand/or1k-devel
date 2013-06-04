
INITRAMFS=/home/bluecmd/Workbench/openrisc/initramfs
SYSROOT=/srv/compilers/openrisc-devel/or1k-linux-gnu/sys-root/
SRCDIR=${PWD}

BUILD=x86_64-redhat-linux
TARGET=or1k-linux-gnu

.PHONY: ncurses zsh zlib openssl openssh busybox all

all: ncurses zsh zlib openssl openssh busybox

ncurses:
	rm -fr /tmp/build-ncurses
	mkdir /tmp/build-ncurses
	(cd /tmp/build-ncurses && \
	  ${SRCDIR}/ncurses-5.9/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr && \
	  make -j7 && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

zsh: ncurses
	rm -fr /tmp/build-zsh
	mkdir /tmp/build-zsh
	(cd /tmp/build-zsh && \
	  LDFLAGS="-static -s" ${SRCDIR}/zsh-5.0.2/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr && \
	  make -j7 && \
	  cp Src/zsh ${INITRAMFS}/usr/bin/)

zlib:
	(cd zlib-1.2.7 && \
	  (make clean || true) && \
	  CC=${TARGET}-gcc CXX=${TARGET}-gcc ./configure --prefix=/usr && \
	  make -j7 && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

openssl: zlib
	(cd openssl-1.0.1c && \
	  (make clean || true) && \
	  ./Configure dist --openssldir=/etc/ssl --prefix=/usr threads -D_REENTRANT && \
	  make CC="${TARGET}-gcc" AR="${TARGET}-ar r" RANLIB="${TARGET}-ranlib" &&\
	  make INSTALL_PREFIX=${INITRAMFS} install_sw && \
	  make INSTALL_PREFIX=${SYSROOT} install_sw)

openssh: zlib
	rm -fr /tmp/build-openssh
	mkdir /tmp/build-openssh
	(cd /tmp/build-openssh && \
	  ${SRCDIR}/openssh-6.1p1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr --sysconfdir=/etc/ssh && \
	  sed -i '/^STRIP_OPT=/d' /tmp/build-openssh/Makefile && \
	  make -j7 && \
	  make DESTDIR=${INITRAMFS} install)

busybox:
	(cd busybox-1.21.0 && make clean && make -j7 && make install)

gmp:
	rm -fr /tmp/build-gmp
	mkdir /tmp/build-gmp
	(cd /tmp/build-gmp && \
	  ${SRCDIR}/gmp-5.1.1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ && \
	  make -j7 && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

mpfr: gmp
	rm -fr /tmp/build-mpfr
	mkdir /tmp/build-mpfr
	(cd /tmp/build-mpfr && \
	  ${SRCDIR}/mpfr-3.1.1/configure --host=${TARGET} \
	   --with-gmp=${INITRAMFS}/ \
	    --build=${BUILD} --prefix=/ && \
	  make -j7 && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

mpc: gmp mpfr
	rm -fr /tmp/build-mpc
	mkdir /tmp/build-mpc
	(cd /tmp/build-mpc && \
	  ${SRCDIR}/mpc-1.0.1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ \
	   --with-gmp=${INITRAMFS}/ \
	   --with-mpfr=${INITRAMFS}/ && \
	  make -j7 && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

