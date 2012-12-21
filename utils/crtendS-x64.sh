cd build-x86_64-gcc/x86_64-linux/libgcc

/home/bluecmd/Workbench/openrisc/devel/build-x86_64-gcc/./gcc/xgcc\
   -B/home/bluecmd/Workbench/openrisc/devel/build-x86_64-gcc/./gcc/\
   -B/srv/compilers/openrisc-devel/or1k-linux/bin/\
   -B/srv/compilers/openrisc-devel/or1k-linux/lib/\
   -isystem\
   /srv/compilers/openrisc-devel/or1k-linux/include\
   -isystem\
   /srv/compilers/openrisc-devel/or1k-linux/sys-include\
   \
   \
   \
   -g\
   -O2\
   -O2\
   -g\
   -O2\
   -DIN_GCC\
   -DCROSS_DIRECTORY_STRUCTURE\
   \
   -W\
   -Wall\
   -Wno-narrowing\
   -Wwrite-strings\
   -Wcast-qual\
   -Wstrict-prototypes\
   -Wmissing-prototypes\
   -Wold-style-definition\
   \
   -isystem\
   ./include\
   \
   -I.\
   -I.\
   -I../.././gcc\
   -I../../../or1k-gcc/libgcc\
   -I../../../or1k-gcc/libgcc/.\
   -I../../../or1k-gcc/libgcc/../gcc\
   -I../../../or1k-gcc/libgcc/../include\
   \
   \
   -g0\
   -finhibit-size-directive\
   -fno-inline\
   -fno-exceptions\
   -fno-zero-initialized-in-bss\
   -fno-toplevel-reorder\
   -fno-tree-vectorize\
   -fno-stack-protector\
   -fno-asynchronous-unwind-tables \
   -Dinhibit_libc\
   -I.\
   -I.\
   -I../.././gcc\
   -I../../../or1k-gcc/libgcc\
   -I../../../or1k-gcc/libgcc/.\
   -I../../../or1k-gcc/libgcc/../gcc\
   -I../../../or1k-gcc/libgcc/../include\
   \
   -o\
   crtendS.o\
   -MT\
   crtendS.o\
   -MD\
   -MP\
   -MF\
   crtendS.dep\
   \
   -fPIC\
   -fno-dwarf2-cfi-asm \
   -c\
   ../../../or1k-gcc/libgcc/crtstuff.c\
   -DCRT_END\
   -DCRTSTUFFS_O

cp crtendS.o ~/Workbench/openrisc/devel/crtendS.o
#cp crtendS.o ~/Workbench/openrisc/devel/.crtendS.c
#cd  ~/Workbench/openrisc/devel/
#grep -v "^# " .crtendS.c > crtendS.c

objdump -j .eh_frame -s /srv/compilers/openrisc-devel-ref/lib/gcc/x86_64-linux/4.8.0/crtendS.o

objdump -j .eh_frame -s crtendS.o
