/* Black Cat Library for WonderWitch                                  */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    common header                                                   */

#ifndef _BCAT_H_
#define _BCAT_H_

#include <sys/types.h>

/* Error number */
#define BCERR_OK 0
#define BCERR_FAILED -1
#define BCERR_INVALID_PARAM -2
#define BCERR_OUT_OF_RANGE -3

/* == Needed == */
/* Common functions */
extern void BCInit(void);

/* Display functions */
extern void BCDisp_Init(void);
extern void BCDisp_RotateFont(void *dst, void *src, ushort num);
extern void BCDisp_RotateFont16(void *dst, void *src, ushort num);
extern void BCDisp_RotateFont16P(void *dst, void *src, ushort num);
extern void BCDisp_RotateFontMono(void *dst, void *src, ushort num);

/* Timer functions */
/* System functions */
/* Memory functions */
extern int BCMem_Init(unsigned max_blocks);
extern void *BCMem_Alloc(ushort alloc_size, ushort align);
extern int BCMem_Free(void *ptr);
extern int BCMem_TestIntegrity(void);

/* Resource functions */
/* Console emulate functions */
extern int BCCon_Init(void);
extern int BCCon_CLS(void);
extern int BCCon_Puts(char *str);
extern int BCCon_Printf(char *str, ...);

/* 'Humming Cat' support functions */

/* == Perhaps needed == */
/* Key functions */
/* Com-port functions */
/* RTC functions */
/* File system functions */

#endif /* _BCAT_H_ */
