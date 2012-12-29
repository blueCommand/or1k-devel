TARGET=or1k-linux

all: stage-gcc gdb

clean:
	rm -fr /srv/compilers/openrisc-devel/*
	rm -f *-stamp || true
	rm -fr build-*

binutils: binutils-stamp
gdb: gdb-stamp
boot-gcc: boot-gcc-stamp
linux-headers: linux-headers-stamp
boot-eglibc: boot-eglibc-stamp
stage-gcc: stage-gcc-stamp
uclibc: uclibc-stamp
eglibc: eglibc-stamp
gcc: gcc-stamp

.PHONY: all clean binutils gdb boot-gcc linux-headers boot-eglibc stage-gcc uclibc eglibc gcc

binutils-stamp:
	rm -fr build-or1k-src
	mkdir build-or1k-src
	(cd build-or1k-src && \
	../or1k-src/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss && \
	make -j && \
	make install)
	touch $(@)

gdb-stamp:
	rm -fr build-or1k-gdb
	mkdir build-or1k-gdb
	(cd build-or1k-gdb && \
	LDFLAGS='-lsim' ../gdb-7.2/configure --target=or32-linux --prefix=/srv/compilers/openrisc-devel && \
	make -j7 && \
	make install)
	touch $(@)

boot-gcc-stamp: binutils
	rm -fr build-or1k-gcc
	mkdir build-or1k-gcc
	(cd build-or1k-gcc && \
	../or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-libssp \
		--srcdir=../or1k-gcc --enable-languages=c --without-headers \
		--enable-threads=single --disable-libgomp --disable-libmudflap \
		--disable-shared --disable-libquadmath --disable-libatomic && \
	make -j7 && \
	make install)
	touch $(@)

linux-headers-stamp:
	cd ../linux-3.6.10 && \
	make ARCH="openrisc" INSTALL_HDR_PATH=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr headers_install
	touch $(@)

uclibc-stamp: linux-headers boot-gcc
	(cd uClibc-or1k && \
	make CROSS_COMPILER_PREFIX=${TARGET}- clean && \
	make ARCH=or1k defconfig && \
	make PREFIX=/srv/compilers/openrisc-devel CROSS_COMPILER_PREFIX=${TARGET}- SYSROOT=/srv/compilers/openrisc-devel/${TARGET}/sys-root TARGET=${TARGET} -j7 && \
	make PREFIX=/srv/compilers/openrisc-devel/${TARGET}/sys-root CROSS_COMPILER_PREFIX=${TARGET}- SYSROOT=/srv/compilers/openrisc-devel/${TARGET}/sys-root TARGET=${TARGET} install)
	touch $(@)

boot-eglibc-stamp: linux-headers boot-gcc
	rm -fr build-eglibc
	mkdir build-eglibc
	(cd build-eglibc && \
	CC=or1k-linux-gcc ../eglibc/libc/configure --host=or1k-linux \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include \
		--disable-profile --without-gd --without-cvs --enable-add-ons \
		--disable-build-nscd --disable-nscd --disable-shared && \
	make -j7 lib && \
	make install_root=/srv/compilers/openrisc-devel/${TARGET}/sys-root install -k -j7 || true)
	cp eglibc/libc/include/gnu/stubs.h /srv/compilers/openrisc-devel/or1k-linux/sys-root/usr/include/gnu/
	touch $(@)

stage-gcc-stamp: boot-eglibc
	rm -fr build-or1k-gcc
	mkdir build-or1k-gcc
	(cd build-or1k-gcc && \
	../or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ \
		--disable-libgomp --disable-libmudflap --disable-libatomic \
		--enable-threads=single \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	touch $(@)

# These do not work yet
eglibc-stamp: stage-gcc
	rm -fr build-eglibc
	mkdir build-eglibc
	(cd build-eglibc && \
	CC=or1k-linux-gcc ../eglibc/libc/configure --host=or1k-linux \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include \
		--disable-profile --without-gd --without-cvs --enable-add-ons \
		--disable-build-nscd --disable-nscd && \
	make -j7 && \
	make cross-compiling=yes install_root=/srv/compilers/openrisc-devel/${TARGET}/sys-root install-headers install-lib)
	touch $(@)

gcc-stamp: eglibc
	rm -fr build-or1k-gcc
	mkdir build-or1k-gcc
	(cd build-or1k-gcc && \
	../or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	touch $(@)


