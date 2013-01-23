TARGET=or1k-linux
TARGET_REG=or1k-linux-uclibc
ARCH=openrisc
DIR=${PWD}

#TARGET=x86_64-linux
NATIVE_TARGET=x86_64-linux
#ARCH=x86_64

all: stage-gcc gdb

clean:
	rm -fr /srv/compilers/openrisc-devel/*
	rm -f *-stamp || true
	rm -fr /tmp/build-*

binutils: binutils-stamp
gdb: gdb-stamp
boot-gcc: boot-gcc-stamp
linux-headers: linux-headers-stamp
uclibc: uclibc-stamp
eglibc: eglibc-stamp
gcc: gcc-stamp
gcc-uclibc: gcc-uclibc-stamp
gcc-native: gcc-native-stamp
dejagnu: dejagnu-stamp

.PHONY: all clean binutils gdb boot-gcc linux-headers uclibc eglibc
.PHONY: gcc gcc-uclibc gcc-native dejagnu

binutils-stamp:
	rm -fr /tmp/build-or1k-src
	mkdir /tmp/build-or1k-src
	(cd /tmp/build-or1k-src && \
	${DIR}/or1k-src/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss --enable-cgen-maint && \
	make -j && \
	make install)
	touch $(@)

boot-gcc-stamp: binutils-stamp
	rm -fr /tmp/build-or1k-gcc
	mkdir /tmp/build-or1k-gcc
	(cd /tmp/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-libssp --disable-decimal-float --enable-tls \
		--enable-languages=c --without-headers --disable-sjlj-exceptions \
		--enable-threads=single --disable-libgomp --disable-libmudflap \
		--disable-shared --disable-libquadmath --disable-libatomic && \
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
	rm -fr /tmp/build-or1k-gcc
	mkdir /tmp/build-or1k-gcc
	(cd /tmp/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap --enable-tls \
		--disable-lto --disable-sjlj-exceptions \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	touch $(@)

eglibc-stamp: linux-headers-stamp boot-gcc-stamp
	rm -fr /tmp/build-eglibc
	mkdir /tmp/build-eglibc
	(cd /tmp/build-eglibc && \
	CC=${TARGET}-gcc ${DIR}/eglibc/libc/configure --host=${TARGET} \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include \
		--disable-profile --without-gd --without-cvs --enable-add-ons && \
	make -j7 && \
	make install_root=/srv/compilers/openrisc-devel/${TARGET}/sys-root install -j7)
	cp eglibc/libc/include/gnu/stubs.h /srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include/gnu/
	touch $(@)

eglibc-pic-stamp: linux-headers-stamp boot-gcc-stamp
	rm -fr /tmp/build-eglibc
	mkdir /tmp/build-eglibc
	(cd /tmp/build-eglibc && \
	CC=${TARGET}-gcc CFLAGS="-fPIC -g -O" ${DIR}/eglibc/libc/configure --host=${TARGET} \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include \
		--disable-profile --without-gd --without-cvs --enable-add-ons \
		libc_cv_pic_default=yes  && \
	make -j7 && \
	make install_root=/srv/compilers/openrisc-devel/${TARGET}/sys-root install -j7)
	cp eglibc/libc/include/gnu/stubs.h /srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include/gnu/
	touch $(@)

gcc-stamp: eglibc-stamp
	rm -fr /tmp/build-or1k-gcc
	mkdir /tmp/build-or1k-gcc
	(cd /tmp/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap --enable-tls --disable-sjlj-exceptions \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make -j7 && \
	make install)
	touch $(@)

gcc-native-stamp:
	rm -fr /tmp/build-native-gcc
	mkdir /tmp/build-native-gcc
	(cd /tmp/build-native-gcc && \
	${DIR}/or1k-gcc/configure --prefix=/srv/compilers/native-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap --enable-tls --disable-sjlj-exceptions \
		--disable-multilib && \
	make -j7 && \
	make install)
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
		--with-sysroot --disable-newlib --disable-libgloss --enable-cgen-maint && \
	make -j && \
	make install)

boot-gcc-regression: binutils-regression
	rm -fr /tmp/build-reg-gcc
	mkdir /tmp/build-reg-gcc
	(cd /tmp/build-reg-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET_REG} --prefix=/srv/compilers/openrisc-reg \
		--disable-libssp --disable-decimal-float --enable-tls \
		--enable-languages=c --without-headers --disable-sjlj-exceptions \
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
	make PREFIX=/srv/compilers/openrisc-reg CROSS_COMPILER_PREFIX=${TARGET_REG}- SYSROOT=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root TARGET_REG=${TARGET_REG} -j7 && \
	make PREFIX=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root CROSS_COMPILER_PREFIX=${TARGET_REG}- SYSROOT=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root TARGET_REG=${TARGET_REG} install)

gcc-uclibc-regression: uclibc-regression
	rm -fr /tmp/build-reg-gcc
	mkdir /tmp/build-reg-gcc
	(cd /tmp/build-reg-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET_REG} --prefix=/srv/compilers/openrisc-reg \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap --enable-tls \
		--disable-lto --disable-sjlj-exceptions \
		--with-sysroot=/srv/compilers/openrisc-reg/${TARGET_REG}/sys-root --disable-multilib && \
	make -j7 && \
	make install)

clean-regression:
	rm -fr /srv/compilers/openrisc-reg/*
	mkdir -p /srv/compilers/openrisc-reg/

.PHONY: binutils-regression boot-gcc-regression linux-headers-regression
.PHONY: uclibc-regression gcc-uclibc-regression clean-regression
.PHONY: check

check: gcc-uclibc-regression dejagnu
	ln -s /srv/compilers/openrisc-reg/bin/${TARGET_REG}-gcc /srv/compilers/openrisc-reg/bin/gcc
	ln -s /srv/compilers/openrisc-reg/bin/${TARGET_REG}-g++ /srv/compilers/openrisc-reg/bin/g++
	(export PATH="/srv/compilers/openrisc-test/bin:${PATH}" && \
	cd /tmp/build-reg-gcc && \
	make check RUNTESTFLAGS="--target_board=or1k-linux-sim --target_triplet=or1k-unknown-linux-gnu" OR1K_IP="192.168.255.200")

