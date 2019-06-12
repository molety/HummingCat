include ..\Makefile.dmc

PROG=hcplay
LIBWWUSR=..\libbcat\libbcat.lib

all:		$(PROG).fx

$(PROG).fx:	$(PROG).bin $(PROG).cf
$(PROG).bin:	$(PROG).o
$(PROG).o:	$(PROG).c ..\bchcat.h
