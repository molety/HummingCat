/* 可変引数リスト操作用マクロ for WonderWitch (実用性は不明)            */
/* 参考にしたもの: Digital Mars C++の stdarg.h                          */
/*               : LSI-C for WonderWitchの stdarg.h                     */
/*               : Cプログラミングの非常識(河西朝雄, 技術評論社)        */
/*               : プログラミング言語C 第2版(K&R, 石田晴久訳, 共立出版) */

#include <sys/types.h>

#ifndef _STDARG_H_
#define _STDARG_H_

#define argsize(arg) ((sizeof(arg) + 1) & ~1)

#define va_start(ap, lastarg) (ap = (va_list)((char *)&(lastarg) + argsize(lastarg)))
#define va_arg(ap, type) (*((type *)(((char *)(ap) += argsize(type)) - argsize(type))))
#define va_end(ap) (ap = NULL)

/* Digital Mars C++では__ss修飾子が要るように思われるが、無くても動く模様 */
/* (sys/types.hでva_listが void * と定義されているので                    */
/*  下手に__ssを付けるとバッティングする)                                 */
/* また、Digital Mars C++付属のstdarg.hでも__ssなしで定義されている       */

#endif /* _STDARG_H_ */
