TARGET=or1k-linux

all: or1k-gcc-uclibc

or1k-clean:
	rm -fr /srv/compilers/openrisc-devel/*
	rm -f or1k-* || true

ref-clean:
	rm -fr /srv/compilers/openrisc-devel-ref/*
	rm -f ref-*

ref-binutils:
	rm -fr build-x86_64-src
	mkdir build-x86_64-src
	(cd build-x86_64-src && \
	../or1k-src/configure --target=x86_64-linux --prefix=/srv/compilers/openrisc-devel-ref \
		--disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup \
		--disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb \
		--with-sysroot --disable-newlib --disable-libgloss && \
	make -j && \
	make install)
	touch $(@)

or1k-binutils:
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


ref-boot-gcc: ref-binutils
	rm -fr build-x86_64-gcc
	mkdir build-x86_64-gcc
	(cd build-x86_64-gcc && \
	../or1k-gcc/configure --target=x86_64-linux --prefix=/srv/compilers/openrisc-devel-ref \
		--disable-libssp \
		--srcdir=../or1k-gcc --enable-languages=c --without-headers \
		--enable-threads=single --disable-libgomp --disable-libmudflap \
		--disable-shared --disable-libquadmath --disable-libatomic --disable-decimal-float && \
	make -j7 && \
	make install)
	touch $(@)

or1k-boot-gcc: or1k-binutils
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

or1k-linux-headers:
	cd ../linux-3.6.10 && \
	make ARCH="openrisc" INSTALL_HDR_PATH=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr headers_install
	touch $(@)

or1k-uclibc: or1k-linux-headers or1k-boot-gcc
	(cd uClibc-or1k && \
	make CROSS_COMPILER_PREFIX=${TARGET}- clean && \
	make ARCH=or1k defconfig && \
	make PREFIX=/srv/compilers/openrisc-devel CROSS_COMPILER_PREFIX=${TARGET}- SYSROOT=/srv/compilers/openrisc-devel/${TARGET}/sys-root TARGET=${TARGET} -j7 && \
	make PREFIX=/srv/compilers/openrisc-devel/${TARGET}/sys-root CROSS_COMPILER_PREFIX=${TARGET}- SYSROOT=/srv/compilers/openrisc-devel/${TARGET}/sys-root TARGET=${TARGET} install)
	touch $(@)

or1k-eglibc:
	rm -fr build-eglibc
	mkdir build-eglibc
	(cd build-eglibc && \
	CC=or1k-linux-gcc ../eglibc-src/libc/configure --host=or1k-linux \
		--prefix=/usr \
		--with-headers=/srv/compilers/openrisc-devel/${TARGET}/sys-root/usr/include \
		--disable-profile --without-gd --without-cvs --enable-add-ons && \
	make)
	touch $(@)

or1k-gcc-uclibc: or1k-uclibc
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
