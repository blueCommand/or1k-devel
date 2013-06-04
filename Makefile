TARGET=or1k-linux-gnu
TARGET_REG=or1k-linux-gnu
ARCH=openrisc
DIR=${PWD}
#EXTRA_BINUTILS="--enable-cgen-maint"

NATIVE_TARGET=x86_64-linux

all: stage-gcc gdb

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
eglibc: eglibc-stamp
gcc: gcc-stamp
gcc-uclibc: gcc-uclibc-stamp
gcc-native: gcc-native-stamp
gcc-foreign: gcc-foreign-stamp
dejagnu: dejagnu-stamp

.PHONY: all clean binutils gdb boot-gcc linux-headers uclibc eglibc
.PHONY: gcc gcc-uclibc gcc-native gcc-foreign dejagnu

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
	cd ../or1k-linux && \
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

eglibc-stamp: linux-headers-stamp boot-gcc-stamp
	rm -fr /tmp/build-eglibc
	mkdir /tmp/build-eglibc
	(cd /tmp/build-eglibc && \
	${DIR}/eglibc/libc/configure --host=${TARGET} \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include \
		--without-gd --without-cvs --enable-add-ons  && \
	make -j7 && \
	make install_root=/srv/compilers/openrisc-devel/${TARGET}/sys-root install -j7 && \
	make install_root=${DIR}/../initramfs install -j7)
	cp eglibc/libc/include/gnu/stubs.h /srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include/gnu/
	touch $(@)

gcc-stamp: eglibc-stamp
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


# These are for regression testing
binutils-regression: clean-regression
	rm -fr /tmp/build-reg-src
	mkdir /tmp/build-reg-src
	(cd /tmp/build-reg-src && \
	${DIR}/or1k-src/configure --target=${TARGET_REG} --prefix=/srv/compilers/openrisc-reg \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss && \
	make -j && \
	make install)

boot-gcc-regression: binutils-regression
	rm -fr /tmp/build-reg-gcc
	mkdir /tmp/build-reg-gcc
	(export PATH="/srv/compilers/openrisc-reg/bin:${PATH}" && \
	cd /tmp/build-reg-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET_REG} --prefix=/srv/compilers/openrisc-reg \
		--disable-libssp --disable-decimal-float \
		--enable-languages=c --without-headers \
		--enable-threads=single --disable-libgomp --disable-libmudflap \
		--disable-shared --disable-libquadmath --disable-libatomic && \
	make -j7 && \
	make install)

linux-headers-regression: clean-regression
	cd ../linux-3.6.10 && \
	make ARCH="${ARCH}" INSTALL_HDR_PATH=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root/usr headers_install

uclibc-regression: linux-headers-regression boot-gcc-regression
	(export PATH="/srv/compilers/openrisc-reg/bin:${PATH}" && \
	cd uClibc-or1k && \
	make CROSS_COMPILER_PREFIX=${TARGET_REG}- clean && \
	make ARCH=or1k defconfig && \
	make \
		CROSS_COMPILER_PREFIX=${TARGET_REG}- \
		SYSROOT=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root \
		-j7 && \
	make \
		PREFIX=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root \
		CROSS_COMPILER_PREFIX=${TARGET_REG}- \
		SYSROOT=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root \
		install)
	cp -aR /srv/compilers/openrisc-reg/${TARGET_REG}/lib/*.so* ${DIR}/../initramfs-reg/lib/
	/srv/compilers/openrisc-reg/bin/${TARGET_REG}-strip ${DIR}/../initramfs-reg/lib/*.so* || true

eglibc-regression: linux-headers-regression boot-gcc-regression
	rm -fr /tmp/build-reg-eglibc
	mkdir /tmp/build-reg-eglibc
	(export PATH="/srv/compilers/openrisc-reg/bin:${PATH}" && \
	cd /tmp/build-reg-eglibc && \
	${DIR}/eglibc/libc/configure --host=${TARGET_REG} \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root/usr/include \
		--disable-profile --without-gd --without-cvs --enable-add-ons  && \
		make -j7 && \
		make install_root=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root install -j7 && \
		make install_root=${DIR}/../initramfs-reg install -j7)
	cp eglibc/libc/include/gnu/stubs.h /srv/compilers/openrisc-reg/${TARGET_REG}/sys-root/usr/include/gnu/
	/srv/compilers/openrisc-reg/bin/${TARGET_REG}-strip ${DIR}/../initramfs-reg/lib/*.so* || true

gcc-uclibc-regression: uclibc-regression
	rm -fr /tmp/build-reg-gcc
	mkdir /tmp/build-reg-gcc
	(export PATH="/srv/compilers/openrisc-reg/bin:${PATH}" && \
	cd /tmp/build-reg-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET_REG} --prefix=/srv/compilers/openrisc-reg \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap \
		--with-sysroot=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	cp -aR /srv/compilers/openrisc-reg/${TARGET_REG}/lib/*.so* ${DIR}/../initramfs-reg/lib/
	/srv/compilers/openrisc-reg/bin/${TARGET_REG}-strip ${DIR}/../initramfs-reg/lib/*.so* || true

gcc-eglibc-regression: eglibc-regression
	rm -fr /tmp/build-reg-gcc
	mkdir /tmp/build-reg-gcc
	(export PATH="/srv/compilers/openrisc-reg/bin:${PATH}" && \
	cd /tmp/build-reg-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET_REG} --prefix=/srv/compilers/openrisc-reg \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap \
		--with-sysroot=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	cp -aR /srv/compilers/openrisc-reg/${TARGET_REG}/lib/*.so* ${DIR}/../initramfs-reg/lib/
	/srv/compilers/openrisc-reg/bin/${TARGET_REG}-strip ${DIR}/../initramfs-reg/lib/*.so* || true

clean-regression:
	rm -fr /srv/compilers/openrisc-reg/*
	mkdir -p /srv/compilers/openrisc-reg/
	rm -fr /tmp/build-reg-*
	rm -fr ${DIR}/../initramfs-reg/lib ${DIR}/../initramfs-reg/usr/lib
	echo WARNING: Make sure that ${TARGET_REG} is correct
	sleep 10

.PHONY: binutils-regression boot-gcc-regression linux-headers-regression
.PHONY: uclibc-regression gcc-uclibc-regression clean-regression
.PHONY: check

check-gcc-uclibc: gcc-uclibc-regression dejagnu
	ln -s /srv/compilers/openrisc-reg/bin/${TARGET_REG}-gcc /srv/compilers/openrisc-reg/bin/gcc
	ln -s /srv/compilers/openrisc-reg/bin/${TARGET_REG}-g++ /srv/compilers/openrisc-reg/bin/g++
	(export PATH="/srv/compilers/openrisc-test/bin:${PATH}" && \
	cd /tmp/build-reg-gcc && \
	make check-c check-c++ RUNTESTFLAGS="--target_board=or1k-linux-sim --target_triplet=or1k-unknown-linux-gnu" OR1K_IP="192.168.255.200")


check-gcc: gcc-eglibc-regression dejagnu
	ln -s /srv/compilers/openrisc-reg/bin/${TARGET_REG}-gcc /srv/compilers/openrisc-reg/bin/gcc
	ln -s /srv/compilers/openrisc-reg/bin/${TARGET_REG}-g++ /srv/compilers/openrisc-reg/bin/g++
	(export PATH="/srv/compilers/openrisc-test/bin:${PATH}" && \
	cd /tmp/build-reg-gcc && \
	make check-c check-c++ RUNTESTFLAGS="--target_board=or1k-linux-sim --target_triplet=or1k-unknown-linux-gnu" OR1K_IP="192.168.255.200")

