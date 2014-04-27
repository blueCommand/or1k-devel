#!/bin/sh -e

or1k-linux-gnu-as simboot.S -o simboot.o
or1k-linux-gnu-as loader.S -o loader.o

or1k-linux-gnu-ld -T simboot.ld loader.o simboot.o -o sim.elf
or1k-linux-gnu-ld -T bootrom.ld loader.o -o bootrom.elf

or1k-linux-gnu-objcopy -O binary bootrom.elf bootrom.bin
~/work/orpsocv2/sw/utils/bin2vlogarray < bootrom.bin > bootrom.v
