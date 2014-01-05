TARGET=or1k-linux-gnu
TARGET_REG=or1k-linux-gnu
ARCH=openrisc
DIR=${PWD}
#EXTRA_BINUTILS="--enable-cgen-maint"

NATIVE_TARGET=x86_64-linux

all: linux

clean:
	(cd linux/; ARHC="openrisc" make clean)
	rm -fr /srv/compilers/openrisc-devel/*
	rm -f .building .*-stamp || true
	rm -fr /tmp/build-*
	rm -fr ${DIR}/../initramfs/lib ${DIR}/../initramfs/usr/lib

binutils: .binutils-stamp
boot-gcc: .boot-gcc-stamp
linux-headers: .linux-headers-stamp
glibc: .glibc-stamp
gcc: .gcc-stamp
dejagnu: .dejagnu-stamp
or1ksim: .or1ksim-stamp
root: .root-stamp
linux: .linux-stamp
gdb: .gdb-stamp
gdbserver: .gdbserver-stamp

.PHONY: all clean binutils boot-gcc linux-headers glibc gcc dejagnu
.PHONY: or1ksim root linux gdb gdbserver

.binutils-stamp:
	echo "$(@)" > .building
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

.boot-gcc-stamp: .binutils-stamp
	echo "$(@)" > .building
	rm -fr /tmp/build-or1k-gcc
	mkdir /tmp/build-or1k-gcc
	(cd /tmp/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-libssp --disable-decimal-float --enable-vtable-verify \
		--enable-languages=c --without-headers \
		--enable-threads=single --disable-libgomp --disable-libmudflap \
		--disable-shared --disable-libquadmath --disable-libatomic && \
	make -j && \
	make install)
	touch $(@)

.linux-headers-stamp:
	echo "$(@)" > .building
	cd linux && \
	make ARCH="${ARCH}" INSTALL_HDR_PATH=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr headers_install && \
	make ARCH="${ARCH}" INSTALL_HDR_PATH=${DIR}/../initramfs/usr headers_install
	touch $(@)

.glibc-stamp: .linux-headers-stamp .boot-gcc-stamp
	echo "$(@)" > .building
	rm -fr /tmp/build-or1k-glibc
	mkdir /tmp/build-or1k-glibc
	(cd /tmp/build-or1k-glibc && \
	${DIR}/or1k-glibc/configure --host=${TARGET} \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include && \
	make -C ${DIR}/or1k-glibc/locale -r objdir="/tmp/build-or1k-glibc" C-translit.h && \
	make -j && \
	make install_root=/srv/compilers/openrisc-devel/${TARGET}/sys-root install -j && \
	make install_root=${DIR}/../initramfs install -j)
	touch $(@)

.gcc-stamp: .glibc-stamp
	echo "$(@)" > .building
	rm -fr /tmp/build-or1k-gcc
	mkdir /tmp/build-or1k-gcc
	(cd /tmp/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make -j && \
	make install)
	cp -aR /srv/compilers/openrisc-devel/${TARGET}/lib/*.so* ${DIR}/../initramfs/lib/
	${TARGET}-strip ${DIR}/../initramfs/lib/*.so* || true
	touch $(@)

.dejagnu-stamp:
	echo "$(@)" > .building
	rm -fr /tmp/build-or1k-dejagnu
	mkdir /tmp/build-or1k-dejagnu
	(cd /tmp/build-or1k-dejagnu && \
	${DIR}/or1k-dejagnu/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-test &&\
	make -j && \
	make install)
	cp -v regression/or1k-linux-sim.exp /srv/compilers/openrisc-test/share/dejagnu/baseboards/
	touch $(@)

.or1ksim-stamp:
	echo "$(@)" > .building
	rm -fr /tmp/build-or1ksim
	mkdir /tmp/build-or1ksim
	(cd /tmp/build-or1ksim && \
	${DIR}/or1ksim/configure && \
	make -j && sudo make install)
	touch $(@)

.root-stamp: .gcc-stamp
	echo "$(@)" > .building
	(cd tools && make)
	touch $(@)

.linux-stamp: .root-stamp
	echo "$(@)" > .building
	cp Linux-config linux/.config
	sed -i 's/elf32-or32/elf32-or1k/g' linux/arch/openrisc/kernel/vmlinux.lds*
	(cd linux && \
	ARCH="openrisc" make -j)
	touch $(@)

# (2014-01-05, bluecmd) GDB do not work as of yet
.gdb-stamp:
	echo "$(@)" > .building
	rm -fr /tmp/build-or1k-gdb
	mkdir /tmp/build-or1k-gdb
	(cd /tmp/build-or1k-gdb && \
	${DIR}/or1k-src/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-tk --disable-tcl --disable-itcl --disable-libgui --disable-werror && \
	make -j all-bfd && \
	make -j all-gdb && \
	make install-gdb)
	touch $(@)

# (2014-01-05, bluecmd) GDB do not work as of yet
.gdbserver-stamp:
	echo "$(@)" > .building
	rm -fr /tmp/build-or1k-gdbserver
	mkdir /tmp/build-or1k-gdbserver
	(cd /tmp/build-or1k-gdbserver && \
	${DIR}/or1k-src/gdb/gdbserver/configure --host=${TARGET} \
		--prefix=/srv/compilers/openrisc-devel \
		--disable-werror && \
	make -j && \
	make install)
	touch $(@)
