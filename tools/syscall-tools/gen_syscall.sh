#!/bin/sh

IFS='
'


:> /tmp/syscalls
for i in `cat syscalls`
do

  NAME=`echo $i | cut -f 2 -d " "`
  NUMBER=`echo $i | cut -f 3 -d " "`

  if echo $NUMBER | grep "__" > /dev/null; then
    NUMBER=`grep -m1 "define $NUMBER " syscalls-defs | cut -f 3 -d " "`
  fi

  echo $NAME $NUMBER >> /tmp/syscalls
done

sed -i 's/^__NR_//' /tmp/syscalls
sort -k2 -n /tmp/syscalls > /tmp/syscalls-sorted

PREV_NUMBER=-1
for i in `cat /tmp/syscalls-sorted`
do
  NAME=`echo $i | cut -f 1 -d " "`
  NUMBER=`echo $i | cut -f 2 -d " "`

  if [ $(($PREV_NUMBER + 1)) != $NUMBER ]; then
    for i in `seq $(($PREV_NUMBER + 1)) $(($NUMBER - 1))`
    do
      echo -e "{ MA, \t0, \tNULL, \t\t\tNULL \t\t\t}, /* $i (unused) */"
    done
  fi

  LINE=""
  if [ `grep "sys_$NAME," linux/powerpc/syscallent.h -c` == "0" ]; then
    if [ `grep "\"$NAME\"" linux/powerpc/syscallent.h -c` == "0" ]; then
      if [ `grep "\"$NAME\"" linux/i386/syscallent.h -c` == "0" ]; then
	continue
      else
	LINE=`grep -m1 "\"$NAME\"" linux/i386/syscallent.h`
      fi
    else
      LINE=`grep -m1 "\"$NAME\"" linux/powerpc/syscallent.h`
    fi
  else
    LINE=`grep -m1 "sys_$NAME," linux/powerpc/syscallent.h`
  fi

  ARGS=`echo $LINE | cut -f 2 -d '{' | cut -f 1 -d ','`
  FLAGS=`echo $LINE | cut -f 2 -d '{' | cut -f 2 -d ','`
  FUNC=`echo $LINE | cut -f 2 -d '{' | cut -f 3 -d ','`
  PRINTNAME=`echo $LINE | cut -f 2 -d '{' | cut -f 4 -d ','`

  echo "{ $ARGS, $FLAGS, $FUNC, $PRINTNAME, /* $NUMBER */"

  PREV_NUMBER=$NUMBER
done
