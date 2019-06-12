include ..\Makefile.dmc

TARGETLIB=libbcat.lib
OBJS=bcat.o bcdisp.o bcdisp2.o bctimer.o bcsys.o bcmem.o bcres.o bccon.o \
     bchcat.o

all:		$(TARGETLIB)

$(TARGETLIB):	$(OBJS)
	$(LIB) -c -n $@ $^
