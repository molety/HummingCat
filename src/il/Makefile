include ..\Makefile.dmc

ASDEFINES=-DDEBUG

all:		hcat.il

hcat.il:	hcat.bil hcat.cf
hcat.bil:	hcat.o hccore.o hccore2.o hcmf.o hcenv.o
hcat.o:		hcat.asm hcdef.asm hcmacro.asm cn_table.asm
hccore.o:	hccore.asm hcdef.asm hcmacro.asm
hccore2.o:	hccore2.asm hcdef.asm hcmacro.asm
hcmf.o:		hcmf.asm hcdef.asm hcmacro.asm
hcenv.o:	hcenv.asm hcdef.asm hcmacro.asm

cn_table.asm:
	mktable > cn_table.asm
mktable.exe:	mktable.c
	$(CC) $<
