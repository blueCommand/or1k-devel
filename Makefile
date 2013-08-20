TARGET=or1k-linux-gnu
TARGET_REG=or1k-linux-gnu
ARCH=openrisc
DIR=${PWD}
#EXTRA_BINUTILS="--enable-cgen-maint"

NATIVE_TARGET=x86_64-linux

all: gcc

clean:
	rm -fr /srv/compilers/openrisc-devel/*
	rm -f *-stamp || true
	rm -fr /tmp/build-*
	rm -fr ${DIR}/../initramfs/lib ${DIR}/../initramfs/usr/lib

binutils: binutils-stamp
binutils-native: binutils-native-stamp
gdb: gdb-stamp
boot-gcc: boot-gcc-stamp
linux-headers: linux-headers-stamp
uclibc: uclibc-stamp
glibc: glibc-stamp
gcc: gcc-stamp
gcc-uclibc: gcc-uclibc-stamp
gcc-native: gcc-native-stamp
gcc-foreign: gcc-foreign-stamp
dejagnu: dejagnu-stamp
or1ksim: or1ksim-stamp
root: root-stamp
linux: linux-stamp

.PHONY: all clean binutils gdb boot-gcc linux-headers uclibc glibc
.PHONY: gcc gcc-uclibc gcc-native gcc-foreign dejagnu linux root
.PHONY: or1ksim

binutils-stamp:
	rm -fr /tmp/build-or1k-src
	mkdir /tmp/build-or1k-src
	(cd /tmp/build-or1k-src && \
	${DIR}/or1k-src/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss ${EXTRA_BINUTILS} && \
	make -j && \
	make install)
	touch $(@)

gdb-stamp:
	rm -fr /tmp/build-or1k-gdb
	mkdir /tmp/build-or1k-gdb
	(cd /tmp/build-or1k-gdb && \
	${DIR}/or1k-src/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-tk --disable-tcl --disable-itcl --disable-libgui --disable-werror && \
	make -j all-bfd && \
	make -j all-gdb && \
	make install-gdb)
	touch $(@)

gdbserver-stamp:
	rm -fr /tmp/build-or1k-gdbserver
	mkdir /tmp/build-or1k-gdbserver
	(cd /tmp/build-or1k-gdbserver && \
	${DIR}/or1k-src/gdb/gdbserver/configure --host=${TARGET} \
		--prefix=/srv/compilers/openrisc-devel \
		--disable-werror && \
	make -j && \
	make install)
	touch $(@)

binutils-native-stamp:
	rm -fr /tmp/build-native-src
	mkdir /tmp/build-native-src
	(cd /tmp/build-native-src && \
	${DIR}/or1k-src/configure --target=${TARGET_NATIVE} --prefix=/srv/compilers/native-devel \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss && \
	make -j && \
	make install)
	touch $(@)

binutils-foreign-stamp:
	rm -fr /tmp/build-foreign-src
	mkdir /tmp/build-foreign-src
	(cd /tmp/build-foreign-src && \
	${DIR}/or1k-src/configure --target=${TARGET} --host=${TARGET} --prefix=/usr \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss --disable-werror && \
	make -j && \
	make DESTDIR=${DIR}/../initramfs/ install)
	touch $(@)

boot-gcc-stamp: binutils-stamp
	rm -fr /tmp/build-or1k-gcc
	mkdir /tmp/build-or1k-gcc
	(cd /tmp/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-libssp --disable-decimal-float \
		--enable-languages=c --without-headers \
		--enable-threads=single --disable-libgomp --disable-libmudflap \
		--disable-shared --disable-libquadmath --disable-libatomic && \
	make -j7 && \
	make install)
	touch $(@)

linux-headers-stamp:
	cd linux && \
	make ARCH="${ARCH}" INSTALL_HDR_PATH=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr headers_install && \
	make ARCH="${ARCH}" INSTALL_HDR_PATH=${DIR}/../initramfs/usr headers_install
	touch $(@)

uclibc-stamp: linux-headers-stamp boot-gcc-stamp
	(cd uClibc-or1k && \
	make CROSS_COMPILER_PREFIX=${TARGET}- clean && \
	make ARCH=or1k defconfig && \
	make \
		CROSS_COMPILER_PREFIX=${TARGET}- \
		SYSROOT=/srv/compilers/openrisc-devel/${TARGET}/sys-root \
		-j7 && \
	make \
		PREFIX=/srv/compilers/openrisc-devel/${TARGET}/sys-root \
		CROSS_COMPILER_PREFIX=${TARGET}- \
		SYSROOT=/srv/compilers/openrisc-devel/${TARGET}/sys-root \
		install)
	cp -aR  /srv/compilers/openrisc-devel/${TARGET}/sys-root/lib ${DIR}/../initramfs/
	mkdir -p ${DIR}/../initramfs/usr/
	cp -aR  /srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/lib ${DIR}/../initramfs/usr/
	ln -sf ld-uClibc.so.0 ${DIR}/../initramfs/lib/ld.so.1
	${TARGET}-strip ${DIR}/../initramfs/lib/*.so* || true
	touch $(@)

gcc-uclibc-stamp: uclibc-stamp
	rm -fr /tmp/build-or1k-gcc
	mkdir /tmp/build-or1k-gcc
	(cd /tmp/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	cp -aR /srv/compilers/openrisc-devel/${TARGET}/lib/*.so* ${DIR}/../initramfs/lib/
	${TARGET}-strip ${DIR}/../initramfs/lib/*.so* || true
	touch $(@)

glibc-stamp: linux-headers-stamp boot-gcc-stamp
	rm -fr /tmp/build-glibc
	mkdir /tmp/build-glibc
	(cd /tmp/build-glibc && \
	${DIR}/glibc/configure --host=${TARGET} \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include && \
	make -j7 && \
	make install_root=/srv/compilers/openrisc-devel/${TARGET}/sys-root install -j7 && \
	make install_root=${DIR}/../initramfs install -j7)
	touch $(@)

gcc-stamp: glibc-stamp
	rm -fr /tmp/build-or1k-gcc
	mkdir /tmp/build-or1k-gcc
	(cd /tmp/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	cp -aR /srv/compilers/openrisc-devel/${TARGET}/lib/*.so* ${DIR}/../initramfs/lib/
	${TARGET}-strip ${DIR}/../initramfs/lib/*.so* || true
	touch $(@)

gcc-native-stamp:
	rm -fr /tmp/build-native-gcc
	mkdir /tmp/build-native-gcc
	(export PATH="/srv/compilers/native-devel/bin:${PATH}" && \
	cd /tmp/build-native-gcc && \
	${DIR}/or1k-gcc/configure --prefix=/srv/compilers/native-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap \
		--disable-multilib && \
	make -j7 && \
	make install)
	touch $(@)

gcc-foreign-stamp: binutils-foreign-stamp
	rm -fr /tmp/build-foreign-gcc
	mkdir /tmp/build-foreign-gcc
	(cd /tmp/build-foreign-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --host=${TARGET} --prefix=/usr \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap \
		--disable-lto \
		--with-sysroot=/ \
		--with-build-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root \
		--with-gmp=${DIR}/../initramfs/ \
		--with-mpc=${DIR}/../initramfs/ \
		--with-mpfr=${DIR}/../initramfs/ \
		&& \
	make -j7 && \
	make DESTDIR=${DIR}/../initramfs/ install)
	touch $(@)

dejagnu-stamp:
	rm -fr /tmp/build-or1k-dejagnu
	mkdir /tmp/build-or1k-dejagnu
	(cd /tmp/build-or1k-dejagnu && \
	${DIR}/or1k-dejagnu/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-test &&\
	make -j7 && \
	make install)
	cp -v regression/or1k-linux-sim.exp /srv/compilers/openrisc-test/share/dejagnu/baseboards/
	touch $(@)

or1ksim-stamp:
	rm -fr /tmp/build-or1ksim
	mkdir /tmp/build-or1ksim
	(cd /tmp/build-or1ksim && \
	${DIR}/or1ksim/configure && \
	make -j7)
	touch $(@)

root-stamp: gcc-stamp
	cd tools && make && \
	touch $(@)

linux-stamp: root-stamp
	cd linux && \
	ARCH="openrisc" make -j7 && \
	touch $(@)

