/* Black Cat Library for WonderWitch                                  */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    common functions                                                */

#include <sys/bios.h>
#include <sys/libwwc.h>
#include "../bcat.h"

unsigned BC_HardArch = HARDARCH_WS;

void BCInit(void) {
	BC_HardArch = wwc_get_hardarch();
}
