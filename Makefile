TARGET=or1k-linux-gnu
ARCH=openrisc
DIR=${PWD}
BUILDDIR=/srv/build
MAKEOPTS=-j$(shell grep -E "^processor" /proc/cpuinfo | tail -n 1 | cut -f 2 -d ' ')

# Enable if playing with the linker
#EXTRA_BINUTILS="--enable-cgen-maint"

NATIVE_TARGET=x86_64-linux

all: linux

clean:
	(cd linux/; ARHC="openrisc" make clean)
	rm -fr /srv/compilers/openrisc-devel/*
	rm -f .building .*-stamp || true
	rm -fr ${BUILDDIR}/build-*
	rm -fr ${DIR}/initramfs/lib ${DIR}/initramfs/usr/lib

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
binutils-native: .binutils-native-stamp
gcc-native: .gcc-native-stamp

.PHONY: all clean binutils boot-gcc linux-headers glibc gcc dejagnu
.PHONY: or1ksim root linux gdb gdbserver binutils-native gcc-native

.binutils-stamp:
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-src
	mkdir ${BUILDDIR}/build-or1k-src
	(cd ${BUILDDIR}/build-or1k-src && \
	${DIR}/or1k-src/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss ${EXTRA_BINUTILS} && \
	make ${MAKEOPTS} && \
	make install)
	touch $(@)

.boot-gcc-stamp: .binutils-stamp
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-gcc
	mkdir ${BUILDDIR}/build-or1k-gcc
	(cd ${BUILDDIR}/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-libssp --disable-decimal-float --enable-vtable-verify \
		--enable-languages=c --without-headers \
		--enable-threads=single --disable-libgomp --disable-libmudflap \
		--disable-shared --disable-libquadmath --disable-libatomic && \
	make ${MAKEOPTS} && \
	make install)
	touch $(@)

.linux-headers-stamp:
	echo "$(@)" > .building
	cd linux && \
	make ARCH="${ARCH}" INSTALL_HDR_PATH=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr headers_install && \
	make ARCH="${ARCH}" INSTALL_HDR_PATH=${DIR}/initramfs/usr headers_install
	touch $(@)

.glibc-stamp: .linux-headers-stamp .boot-gcc-stamp
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-glibc
	mkdir ${BUILDDIR}/build-or1k-glibc
	(cd ${BUILDDIR}/build-or1k-glibc && \
	${DIR}/or1k-glibc/configure --host=${TARGET} \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include && \
	make -C ${DIR}/or1k-glibc/locale -r objdir="${BUILDDIR}/build-or1k-glibc" C-translit.h && \
	make ${MAKEOPTS} && \
	make install_root=/srv/compilers/openrisc-devel/${TARGET}/sys-root install -j && \
	make install_root=${DIR}/initramfs install -j)
	touch $(@)

.gcc-stamp: .glibc-stamp
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-gcc
	mkdir ${BUILDDIR}/build-or1k-gcc
	(cd ${BUILDDIR}/build-or1k-gcc && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--enable-languages=c,c++ --enable-threads=posix \
		--disable-libgomp --disable-libmudflap --enable-vtable-verify \
		--with-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root --disable-multilib && \
	make ${MAKEOPTS} && \
	make install)
	cp -aR /srv/compilers/openrisc-devel/${TARGET}/lib/*.so* ${DIR}/initramfs/lib/
	${TARGET}-strip ${DIR}/initramfs/lib/*.so* || true
	touch $(@)

.binutils-native-stamp: .gcc-stamp
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-src-native
	mkdir ${BUILDDIR}/build-or1k-src-native
	(cd ${BUILDDIR}/build-or1k-src-native && \
	${DIR}/or1k-src/configure --host=${TARGET} --target=${TARGET} \
		--prefix=/usr \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss --disable-werror && \
	make ${MAKEOPTS} && \
	make DESTDIR=${DIR}/initramfs/ install)
	touch $(@)

.gcc-native-stamp: .gcc-stamp .binutils-native-stamp
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-gcc-native
	mkdir ${BUILDDIR}/build-or1k-gcc-native
	(cd ${BUILDDIR}/build-or1k-gcc-native && \
	${DIR}/or1k-gcc/configure --target=${TARGET} --host=${TARGET} --prefix=/usr \
		--enable-languages=c,c++ --enable-threads=posix --disable-lto --enable-static \
		--disable-libgomp --disable-libmudflap --enable-vtable-verify \
		--with-sysroot=/ --with-gmp=${DIR}/initramfs/ \
		--with-mpc=${DIR}/initramfs/ \
		--with-mpfr=${DIR}/initramfs/ \
		--with-build-sysroot=/srv/compilers/openrisc-devel/${TARGET}/sys-root && \
	make ${MAKEOPTS} && \
	make DESTDIR=${DIR}/initramfs/ install)
	touch $(@)

.dejagnu-stamp:
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-dejagnu
	mkdir ${BUILDDIR}/build-or1k-dejagnu
	(cd ${BUILDDIR}/build-or1k-dejagnu && \
	${DIR}/or1k-dejagnu/configure --target=${TARGET} \
		--prefix=/srv/compilers/openrisc-devel &&\
	make ${MAKEOPTS} && \
	make install)
	ln -sf ${DIR}/tests/or1k-linux-sim.exp \
		/srv/compilers/openrisc-devel/share/dejagnu/baseboards/
	touch $(@)

.or1ksim-stamp:
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1ksim
	mkdir ${BUILDDIR}/build-or1ksim
	(cd ${BUILDDIR}/build-or1ksim && \
	${DIR}/or1ksim/configure && \
	make ${MAKEOPTS} && sudo make install)
	touch $(@)

.root-stamp: .gcc-stamp
	echo "$(@)" > .building
	(cd tools && make)
	(cd initramfs/; mkdir -p dev proc sys mnt tmp srv)
	sudo rm -f initramfs/etc/ssh/ssh_host_*
	sudo ssh-keygen -f initramfs/etc/ssh/ssh_host_rsa_key -C or1k -N '' -t rsa
	sudo ssh-keygen -f initramfs/etc/ssh/ssh_host_dsa_key -C or1k -N '' -t dsa
	sudo ssh-keygen -f initramfs/etc/ssh/ssh_host_ecdsa_key -C or1k -N '' -t ecdsa
	rmdir initramfs/var/empty
	sudo mkdir initramfs/var/empty
	sudo mkdir -p initramfs/root/.ssh
	sudo cp ~/.ssh/id_rsa.pub initramfs/root/.ssh/authorized_keys
	touch $(@)

.linux-stamp: .boot-gcc-stamp
	echo "$(@)" > .building
	cp Linux-config linux/.config
	sed -i 's/elf32-or32/elf32-or1k/g' linux/arch/openrisc/kernel/vmlinux.lds*
	cp or1ksim.dts linux/arch/openrisc/boot/dts/
	(cd linux && \
	ARCH="openrisc" make ${MAKEOPTS})
	touch $(@)

# (2014-01-05, bluecmd) GDB do not work as of yet
.gdb-stamp:
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-gdb
	mkdir ${BUILDDIR}/build-or1k-gdb
	(cd ${BUILDDIR}/build-or1k-gdb && \
	${DIR}/or1k-src/configure --target=${TARGET} --prefix=/srv/compilers/openrisc-devel \
		--disable-tk --disable-tcl --disable-itcl --disable-libgui --disable-werror && \
	make ${MAKEOPTS} all-bfd && \
	make ${MAKEOPTS} all-gdb && \
	make install-gdb)
	touch $(@)

# (2014-01-05, bluecmd) GDB do not work as of yet
.gdbserver-stamp:
	echo "$(@)" > .building
	rm -fr ${BUILDDIR}/build-or1k-gdbserver
	mkdir ${BUILDDIR}/build-or1k-gdbserver
	(cd ${BUILDDIR}/build-or1k-gdbserver && \
	${DIR}/or1k-src/gdb/gdbserver/configure --host=${TARGET} \
		--prefix=/srv/compilers/openrisc-devel \
		--disable-werror && \
	make ${MAKEOPTS} && \
	make install)
	touch $(@)
