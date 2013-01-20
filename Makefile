TARGET=or1k-linux
ARCH=openrisc

#TARGET=x86_64-linux
#ARCH=x86_64

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
gcc-uclibc: gcc-uclibc-stamp

.PHONY: all clean binutils gdb boot-gcc linux-headers boot-eglibc stage-gcc uclibc eglibc gcc gcc-uclibc

binutils-stamp:
	rm -fr build-or1k-src
	mkdir build-or1k-src
	(cd build-or1k-src && \
	../or1k-src/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss --enable-cgen-maint && \
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

boot-gcc-stamp: binutils-stamp
	rm -fr build-or1k-gcc
	mkdir build-or1k-gcc
	(cd build-or1k-gcc && \
	../or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-libssp --disable-decimal-float --enable-tls \
		--srcdir=../or1k-gcc --enable-languages=c --without-headers \
		--enable-threads=single --disable-libgomp --disable-libmudflap \
		--disable-shared --disable-libquadmath --disable-libatomic --disable-sjlj-exceptions && \
	make -j7 && \
	make install)
	touch $(@)

linux-headers-stamp:
	cd ../linux-3.6.10 && \
	make ARCH="${ARCH}" INSTALL_HDR_PATH=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr headers_install
	touch $(@)

uclibc-stamp: linux-headers-stamp boot-gcc-stamp
	(cd uClibc-or1k && \
	make CROSS_COMPILER_PREFIX=${TARGET}- clean && \
	make ARCH=or1k defconfig && \
	make PREFIX=/srv/compilers/openrisc-devel CROSS_COMPILER_PREFIX=${TARGET}- SYSROOT=/srv/compilers/openrisc-devel/${TARGET}/sys-root TARGET=${TARGET} -j7 && \
	make PREFIX=/srv/compilers/openrisc-devel/${TARGET}/sys-root CROSS_COMPILER_PREFIX=${TARGET}- SYSROOT=/srv/compilers/openrisc-devel/${TARGET}/sys-root TARGET=${TARGET} install)
	touch $(@)

gcc-uclibc-stamp: uclibc-stamp
	rm -fr build-or1k-gcc
	mkdir build-or1k-gcc
	(cd build-or1k-gcc && \
	../or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap --enable-tls \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	touch $(@)

eglibc-stamp: linux-headers-stamp boot-gcc-stamp
	rm -fr build-eglibc
	mkdir build-eglibc
	(cd build-eglibc && \
	CC=${TARGET}-gcc ../eglibc/libc/configure --host=${TARGET} \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include \
		--disable-profile --without-gd --without-cvs --enable-add-ons \
		--disable-build-nscd --disable-nscd && \
	make -j7 && \
	make install_root=/srv/compilers/openrisc-devel/${TARGET}/sys-root install -j7)
	cp eglibc/libc/include/gnu/stubs.h /srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include/gnu/
	touch $(@)

gcc-stamp: eglibc-stamp
	rm -fr build-or1k-gcc
	mkdir build-or1k-gcc
	(cd build-or1k-gcc && \
	../or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap --enable-tls --disable-sjlj-exceptions \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	touch $(@)


