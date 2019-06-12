/* �ψ������X�g����p�}�N�� for WonderWitch (���p���͕s��)            */
/* �Q�l�ɂ�������: Digital Mars C++�� stdarg.h                          */
/*               : LSI-C for WonderWitch�� stdarg.h                     */
/*               : C�v���O���~���O�̔�펯(�͐����Y, �Z�p�]�_��)        */
/*               : �v���O���~���O����C ��2��(K&R, �Γc���v��, �����o��) */

#include <sys/types.h>

#ifndef _STDARG_H_
#define _STDARG_H_

#define argsize(arg) ((sizeof(arg) + 1) & ~1)

#define va_start(ap, lastarg) (ap = (va_list)((char *)&(lastarg) + argsize(lastarg)))
#define va_arg(ap, type) (*((type *)(((char *)(ap) += argsize(type)) - argsize(type))))
#define va_end(ap) (ap = NULL)

/* Digital Mars C++�ł�__ss�C���q���v��悤�Ɏv���邪�A�����Ă������͗l */
/* (sys/types.h��va_list�� void * �ƒ�`����Ă���̂�                    */
/*  �����__ss��t����ƃo�b�e�B���O����)                                 */
/* �܂��ADigital Mars C++�t����stdarg.h�ł�__ss�Ȃ��Œ�`����Ă���       */

#endif /* _STDARG_H_ */
