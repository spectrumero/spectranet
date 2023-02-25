ASOBJS = ar_boot.o vectors.o
OUT = allram.module
STG2LDROBJS = stage2bld.o
STG2LDRBIN = stage2bld.bin
STG2OBJS = stage2.o
STG2BIN = stage2img.bin
STG2P5OBJS = stage2point5.o
STG2P5BIN = stage2p5.bin

all:		stage2ldr module

include ../make.inc

stage2ldr:	stage2 $(STG2LDROBJS)
	$(LD) -o $(STG2LDRBIN) $(STG2LDROBJS) -T standalone.ld

stage2:		stage2p5 $(STG2OBJS)
	$(LD) -o $(STG2BIN) $(STG2OBJS) -T standalone.ld

stage2p5:	$(STG2P5OBJS)
	$(LD) -o $(STG2P5BIN) $(STG2P5OBJS) -T standalone.ld
