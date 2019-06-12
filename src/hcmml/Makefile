include ..\Makefile.dmc
#DOSCDEFINES=-DDEBUG

all:		hcmml.exe #hcedit.fx

hcmml.exe:	hcmml.obj hcmfile.obj hcmcore.obj hcmlex.obj hcmchunk.obj
hcmml.obj:	hcmml.c hcmml.h
hcmfile.obj:	hcmfile.c hcmml.h
hcmcore.obj:	hcmcore.c hcmml.h
hcmlex.obj:	hcmlex.c hcmml.h
hcmchunk.obj:	hcmchunk.c hcmml.h

hcedit.fx:	hcedit.bin hcedit.cf
hcedit.bin:	hcedit.o hcmcore.o hcmlex.o hcmchunk.o
hcedit.o:	hcedit.c
hcmcore.o:	hcmcore.c hcmml.h
hcmlex.o:	hcmlex.c hcmml.h
hcmchunk.o:	hcmchunk.c hcmml.h
