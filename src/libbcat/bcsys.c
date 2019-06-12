/* Black Cat Library for WonderWitch                                  */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    system functions                                                */

#include <sys/bios.h>
#include <sys/libwwc.h>
#include "../bcat.h"

extern BC_HardArch;

unsigned BCSys_GetHardArch(void) {
	return BC_HardArch;
}

void BCSys_GetOwnerInfo(void) {
	wwc_sys_get_ownerinfo(3, (char far *)NULL);
}
