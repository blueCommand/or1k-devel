
INITRAMFS=${PWD}/../initramfs
SYSROOT=/srv/compilers/openrisc-devel/or1k-linux-gnu/sys-root/
SRCDIR=${PWD}
MAKEOPTS=-j$(shell grep -E "^processor" /proc/cpuinfo | tail -n 1 | cut -f 2 -d ' ')
BUILDDIR=/srv/build

BUILD=x86_64-linux-gnu
TARGET=or1k-linux-gnu

.PHONY: ncurses zsh zsh-static zlib openssl openssh busybox strace
.PHONY: all download

all: ncurses zsh zlib openssl openssh busybox

.download-stamp:
	echo ftp://invisible-island.net/ncurses/ncurses-5.9.tar.gz \
	 http://zlib.net/zlib-1.2.8.tar.gz \
	 http://www.openssl.org/source/openssl-1.0.1e.tar.gz \
	 http://www.zsh.org/pub/zsh-5.0.5.tar.bz2 \
	 http://ftp.eu.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-6.4p1.tar.gz \
	 https://gmplib.org/download/gmp/gmp-5.1.3.tar.xz \
	 http://www.mpfr.org/mpfr-current/mpfr-3.1.2.tar.xz \
	 http://www.multiprecision.org/mpc/download/mpc-1.0.1.tar.gz \
	 http://busybox.net/downloads/busybox-1.22.0.tar.bz2 \
	 http://netcologne.dl.sourceforge.net/project/strace/strace/4.8/strace-4.8.tar.xz \
	 | xargs -n 1 -P 0 wget
	echo *.tar.* | xargs -n 1 -P 0 tar -xf
	wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
	wget -O config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
	touch $(@)

download: .download-stamp

ncurses: download
	rm -fr ${BUILDDIR}/build-ncurses
	mkdir ${BUILDDIR}/build-ncurses
	cp config.guess config.sub ${SRCDIR}/ncurses-5.9/
	(cd ${BUILDDIR}/build-ncurses && \
	  ${SRCDIR}/ncurses-5.9/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

zsh: download ncurses
	rm -fr ${BUILDDIR}/build-zsh
	mkdir ${BUILDDIR}/build-zsh
	cp config.guess config.sub ${SRCDIR}/zsh-5.0.5/
	(cd ${BUILDDIR}/build-zsh && \
	  ${SRCDIR}/zsh-5.0.5/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr && \
	  make ${MAKEOPTS} && \
	  cp Src/zsh ${INITRAMFS}/usr/bin/)

zsh-static: download ncurses
	rm -fr ${BUILDDIR}/build-zsh
	mkdir ${BUILDDIR}/build-zsh
	cp config.guess config.sub ${SRCDIR}/zsh-5.0.5/
	(cd ${BUILDDIR}/build-zsh && \
	  LDFLAGS="-static -s" ${SRCDIR}/zsh-5.0.5/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr && \
	  make ${MAKEOPTS} && \
	  cp Src/zsh ${INITRAMFS}/usr/bin/)

zlib: download
	(cd zlib-1.2.8 && \
	  (make clean || true) && \
	  CC=${TARGET}-gcc CXX=${TARGET}-gcc ./configure --prefix=/usr && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

openssl: download zlib
	(cd openssl-1.0.1e && \
	  (make clean || true) && \
	  ./Configure dist --openssldir=/etc/ssl --prefix=/usr threads -D_REENTRANT && \
	  make CC="${TARGET}-gcc" AR="${TARGET}-ar r" RANLIB="${TARGET}-ranlib" &&\
	  make INSTALL_PREFIX=${INITRAMFS} install_sw && \
	  make INSTALL_PREFIX=${SYSROOT} install_sw)

openssh: download zlib
	rm -fr ${BUILDDIR}/build-openssh
	mkdir ${BUILDDIR}/build-openssh
	cp config.guess config.sub ${SRCDIR}/openssh-6.4p1/
	(cd ${BUILDDIR}/build-openssh && \
	  ${SRCDIR}/openssh-6.4p1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr --sysconfdir=/etc/ssh && \
	  sed -i '/^STRIP_OPT=/d' ${BUILDDIR}/build-openssh/Makefile && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS} install)

busybox: download
	cp Busybox-config busybox-1.22.0/.config
	(cd busybox-1.22.0 && make clean && make ${MAKEOPTS} && make install)

# These are used for building native gcc, not built by default
gmp: download
	rm -fr ${BUILDDIR}/build-gmp
	mkdir ${BUILDDIR}/build-gmp
	(cd ${BUILDDIR}/build-gmp && \
	  ${SRCDIR}/gmp-5.1.1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

mpfr: download gmp
	rm -fr ${BUILDDIR}/build-mpfr
	mkdir ${BUILDDIR}/build-mpfr
	(cd ${BUILDDIR}/build-mpfr && \
	  ${SRCDIR}/mpfr-3.1.2/configure --host=${TARGET} \
	   --with-gmp=${INITRAMFS}/ \
	    --build=${BUILD} --prefix=/ && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

mpc: download gmp mpfr
	rm -fr ${BUILDDIR}/build-mpc
	mkdir ${BUILDDIR}/build-mpc
	(cd ${BUILDDIR}/build-mpc && \
	  ${SRCDIR}/mpc-1.0.1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ \
	   --with-gmp=${INITRAMFS}/ \
	   --with-mpfr=${INITRAMFS}/ && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

strace: download
	rm -fr ${BUILDDIR}/build-strace
	mkdir ${BUILDDIR}/build-strace
	(cd ${BUILDDIR}/build-strace && \
	  ${SRCDIR}/strace-4.8/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS} install)

