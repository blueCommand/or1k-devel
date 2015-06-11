TARGET=or1k-elf
ARCH=openrisc
SRCDIR=${PWD}/..
BUILDDIR=/srv/build
MAKEOPTS=-j$(shell grep -E "^processor" /proc/cpuinfo | tail -n 1 | cut -f 2 -d ' ')
SYSROOT=/srv/compilers/openrisc-devel/${TARGET}/sys-root

EXTRA_BINUTILS=--disable-werror

all: gcc

clean:
	rm -fr /srv/compilers/openrisc-devel/${TARGET}
	rm -f .building .*-stamp || true
	rm -fr ${BUILDDIR}/build-*

binutils: .binutils-stamp
boot-gcc: .boot-gcc-stamp
newlib: .newlib-stamp
gcc: .gcc-stamp

.PHONY: all clean binutils boot-gcc newlib gcc

.binutils-stamp:
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-binutils
	mkdir ${BUILDDIR}/build-or1k-binutils
	(cd ${BUILDDIR}/build-or1k-binutils && \
	${SRCDIR}/binutils-gdb/configure --target=${TARGET} \
		--prefix=/srv/compilers/openrisc-devel \
		--with-sysroot ${EXTRA_BINUTILS} && \
	make ${MAKEOPTS} && \
	make install)
	touch $(@)

.boot-gcc-stamp: .binutils-stamp
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-gcc
	mkdir ${BUILDDIR}/build-or1k-gcc
	(cd ${BUILDDIR}/build-or1k-gcc && \
	${SRCDIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-libssp --disable-decimal-float --enable-languages=c --without-headers \
		--disable-libgomp --disable-libmudflap --disable-shared --disable-libquadmath \
		--disable-libatomic && \
	make ${MAKEOPTS} && \
	make install)
	touch $(@)

.newlib-stamp: .boot-gcc-stamp
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-newlib
	mkdir ${BUILDDIR}/build-or1k-newlib
	(cd ${BUILDDIR}/build-or1k-newlib && \
	${SRCDIR}/newlib/newlib/configure --target=${TARGET} \
		--prefix=/srv/compilers/openrisc-devel && \
	make ${MAKEOPTS} && \
	make install)
	touch $(@)

.gcc-stamp: .newlib-stamp
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-gcc
	mkdir ${BUILDDIR}/build-or1k-gcc
	(cd ${BUILDDIR}/build-or1k-gcc && \
	${SRCDIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --disable-libgomp --disable-libmudflap \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib \
		--with-newlib --disable-libssp  --disable-shared && \
	make ${MAKEOPTS} && \
	make install)
	touch $(@)
