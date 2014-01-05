
INITRAMFS=${PWD}/../initramfs
SYSROOT=/srv/compilers/openrisc-devel/or1k-linux-gnu/sys-root/
SRCDIR=${PWD}

BUILD=x86_64-linux-gnu
TARGET=or1k-linux-gnu

.PHONY: ncurses zsh zsh-static zlib openssl openssh busybox all download

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
	 | xargs -n 1 -P 0 wget
	echo *.tar.* | xargs -n 1 -P 0 tar -xf
	wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
	wget -O config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
	touch $(@)

download: .download-stamp

ncurses: download
	rm -fr /tmp/build-ncurses
	mkdir /tmp/build-ncurses
	cp config.guess config.sub ${SRCDIR}/ncurses-5.9/
	(cd /tmp/build-ncurses && \
	  ${SRCDIR}/ncurses-5.9/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr && \
	  make -j && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

zsh: download ncurses
	rm -fr /tmp/build-zsh
	mkdir /tmp/build-zsh
	cp config.guess config.sub ${SRCDIR}/zsh-5.0.5/
	(cd /tmp/build-zsh && \
	  ${SRCDIR}/zsh-5.0.5/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr && \
	  make -j && \
	  cp Src/zsh ${INITRAMFS}/usr/bin/)

zsh-static: download ncurses
	rm -fr /tmp/build-zsh
	mkdir /tmp/build-zsh
	cp config.guess config.sub ${SRCDIR}/zsh-5.0.5/
	(cd /tmp/build-zsh && \
	  LDFLAGS="-static -s" ${SRCDIR}/zsh-5.0.5/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr && \
	  make -j && \
	  cp Src/zsh ${INITRAMFS}/usr/bin/)

zlib: download
	(cd zlib-1.2.8 && \
	  (make clean || true) && \
	  CC=${TARGET}-gcc CXX=${TARGET}-gcc ./configure --prefix=/usr && \
	  make -j && \
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
	rm -fr /tmp/build-openssh
	mkdir /tmp/build-openssh
	cp config.guess config.sub ${SRCDIR}/openssh-6.4p1/
	(cd /tmp/build-openssh && \
	  ${SRCDIR}/openssh-6.4p1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/usr --sysconfdir=/etc/ssh && \
	  sed -i '/^STRIP_OPT=/d' /tmp/build-openssh/Makefile && \
	  make -j && \
	  make DESTDIR=${INITRAMFS} install)

busybox: download
	cp Busybox-config busybox-1.22.0/.config
	(cd busybox-1.22.0 && make clean && make -j && make install)

# These are used for building native gcc, not built by default
gmp: download
	rm -fr /tmp/build-gmp
	mkdir /tmp/build-gmp
	(cd /tmp/build-gmp && \
	  ${SRCDIR}/gmp-5.1.1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ && \
	  make -j && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

mpfr: download gmp
	rm -fr /tmp/build-mpfr
	mkdir /tmp/build-mpfr
	(cd /tmp/build-mpfr && \
	  ${SRCDIR}/mpfr-3.1.2/configure --host=${TARGET} \
	   --with-gmp=${INITRAMFS}/ \
	    --build=${BUILD} --prefix=/ && \
	  make -j && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

mpc: download gmp mpfr
	rm -fr /tmp/build-mpc
	mkdir /tmp/build-mpc
	(cd /tmp/build-mpc && \
	  ${SRCDIR}/mpc-1.0.1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ \
	   --with-gmp=${INITRAMFS}/ \
	   --with-mpfr=${INITRAMFS}/ && \
	  make -j && \
	  make DESTDIR=${INITRAMFS} install && \
	  make DESTDIR=${SYSROOT} install)

