#ifndef __VARS_INCLUDED__
#define __VARS_INCLUDED__

/* Infelizmente não podemos acessar as variáveis declaradas nos códigos em C
   diretamente... Elas estão alocadas em segmentos cuja base é o endereço
   0x00000600, onde o bootsector e o loader são carregados!
   Essas macros permitem o acesso indireto às variáveis. */

/* Endereço linear base */
#define _BASE_OFFSET  0x00000600U

#define CHAR_VAR(x)   (*(char *)((void *)&(x) + _BASE_OFFSET))
#define UCHAR_VAR(x)  (*(unsigned char *)((void *)&(x) + _BASE_OFFSET))
#define SHORT_VAR(x)  (*(short *)((void *)&(x) + _BASE_OFFSET))
#define USHORT_VAR(x) (*(unsigned short *)((void *)&(x) + _BASE_OFFSET))
#define INT_VAR(x)    (*(int *)((void *)&(x) + _BASE_OFFSET))
#define UINT_VAR(x)   (*(unsigned int *)((void *)&(x) + _BASE_OFFSET))

#endif
