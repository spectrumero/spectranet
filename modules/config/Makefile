ASOBJS = configbasic.o configdata.o fs_config_ui.o fs_strings_en.o gen_copycfg.o if_config_ui.o if_configmain.o if_saveconfig.o if_strings_en.o init.o vectors.o
LIBS = -lromui
LIBPATH = -L ../../syslib
FLOBJS = flashwrite.o
FLLDFLAGS = -Ttext 0x3000 $(LIBPATH) -Map $(FLMAP)
FLLIBS = -lflashwrite
FLOUT = flashwrite.bin
FLMAP = $(FLOUT).map
DUMPOBJS = dumpconfig.o
DUMPOUT = dumpconfig.bin
DUMPLDFLAGS = -Ttext 0x8000
SAOBJS = standalone_ifconfig.o gen_copycfg.o if_config_ui.o if_strings_en.o sa_if_saveconfig.o sa_flashwrite.o 
SAOUT = ifconfig.bin
SALDFLAGS = -Ttext 0x8000 $(LIBPATH)
SALIBS = -lflashwrite -lromui
OUT = config.module

all:	flash module dumpcfg standalone
include ../make.inc

flash:	$(FLOBJS)
	$(LD) -o $(FLOUT) $(FLOBJS) $(FLLDFLAGS) $(FLLIBS)

dumpcfg:	$(DUMPOBJS)
	$(LD) -o $(DUMPOUT) $(DUMPOBJS) $(DUMPLDFLAGS)

standalone:	$(SAOBJS)
	$(LD) -o $(SAOUT) $(SAOBJS) $(SALDFLAGS) $(SALIBS)

