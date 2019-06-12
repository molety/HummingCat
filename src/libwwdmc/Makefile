# Extract .obj from DMC library  for WonderWitch

include ..\Makefile.dmc

DMCLIBDIR=$(WWDIR)\dm\lib
SRCLIB=sds.lib
TARGETLIB=libwwdmc.lib
INSTALLDIR=$(WWDIR)\usr\lib

all:		$(TARGETLIB)

$(TARGETLIB):	lmath.obj rand.obj
	$(LIB) -x $(SRCLIB) $^
	$(LIB) -c -n $@ $^

lmath.obj:	$(SRCLIB)
rand.obj:	$(SRCLIB)

$(SRCLIB):
	$(CP) $(DMCLIBDIR)\$(SRCLIB) .

install:
	$(CP) $(TARGETLIB) $(INSTALLDIR)
