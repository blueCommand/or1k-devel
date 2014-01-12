
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
	echo ncurses-5.9.tar.gz \
		zlib-1.2.8.tar.gz \
		openssl-1.0.1e.tar.gz \
		zsh-5.0.5.tar.bz2 \
		openssh-6.4p1.tar.gz \
		gmp-5.1.3.tar.xz \
		mpfr-3.1.2.tar.xz \
		mpc-1.0.1.tar.gz \
		busybox-1.22.0.tar.bz2 \
		strace-4.8.tar.xz \
		| xargs -I {} -n 1 -P 0 -d ' ' wget \
			https://commondatastorage.googleapis.com/bluecmd-openrisc/mirror/{}
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
	cp config.guess config.sub ${SRCDIR}/gmp-5.1.3/
	(cd ${BUILDDIR}/build-gmp && \
	  ${SRCDIR}/gmp-5.1.3/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS}/ install && \
	  make DESTDIR=${SYSROOT} install)

mpfr: download gmp
	rm -fr ${BUILDDIR}/build-mpfr
	mkdir ${BUILDDIR}/build-mpfr
	cp config.guess config.sub ${SRCDIR}/mpfr-3.1.2/
	(cd ${BUILDDIR}/build-mpfr && \
	  ${SRCDIR}/mpfr-3.1.2/configure --host=${TARGET} \
	   --with-gmp=${INITRAMFS}/ \
	    --build=${BUILD} --prefix=/ && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS}/ install && \
	  make DESTDIR=${SYSROOT} install)

mpc: download mpfr gmp
	rm -fr ${BUILDDIR}/build-mpc
	mkdir ${BUILDDIR}/build-mpc
	cp config.guess config.sub ${SRCDIR}/mpc-1.0.1/
	(cd ${BUILDDIR}/build-mpc && \
	  ${SRCDIR}/mpc-1.0.1/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ \
	   --with-gmp=${INITRAMFS}/ \
	   --with-mpfr=${INITRAMFS}/ && \
		patch -p0 < ${SRCDIR}/mpc.patch && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS}/ install && \
	  make DESTDIR=${SYSROOT} install)

strace: download
	rm -fr ${BUILDDIR}/build-strace
	mkdir ${BUILDDIR}/build-strace
	(cd ${BUILDDIR}/build-strace && \
	  ${SRCDIR}/strace-4.8/configure --host=${TARGET} \
	    --build=${BUILD} --prefix=/ && \
	  make ${MAKEOPTS} && \
	  make DESTDIR=${INITRAMFS} install)

