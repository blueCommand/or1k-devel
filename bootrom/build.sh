#!/bin/sh -e

or1k-linux-gnu-gcc -c simboot.S -o simboot.o
or1k-linux-gnu-gcc -c loader.S -o loader.o

or1k-linux-gnu-ld -T simboot.ld loader.o simboot.o -o sim.elf
or1k-linux-gnu-ld -T bootrom.ld loader.o -o bootrom.elf

or1k-linux-gnu-objcopy -O binary bootrom.elf bootrom.bin
~/work/orpsocv2/sw/utils/bin2vlogarray < bootrom.bin | tail -n+65 > bootrom.v
