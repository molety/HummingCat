/* Black Cat Library for WonderWitch                                  */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    'Humming Cat' support functions                                 */

#ifndef _BCHCAT_H_
#define _BCHCAT_H_

#include "hcatil.h"

extern int BCHcat_Init(void);
extern int BCHcat_Release(void);
extern int BCHcat_ExtractPack(void far *pack);
extern int BCHcat_SetScore(unsigned slot, unsigned number);
extern int BCHcat_CheckStatus(unsigned slot);
extern int BCHcat_Play(unsigned slot);
extern int BCHcat_Continue(unsigned slot);
extern int BCHcat_Stop(unsigned slot);
extern int BCHcat_EnableOutput(unsigned slot, unsigned track);
extern int BCHcat_ChangeSpeed(unsigned slot, unsigned speed);
extern int BCHcat_ChangeMasterVol(unsigned slot, unsigned track,
								  unsigned mastervol);
extern int BCHcat_SetDriverMode(unsigned func, unsigned param);

#endif /* _BCHCAT_H_ */
