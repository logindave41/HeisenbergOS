#ifndef __MEMORY_INCLUDED__
#define __MEMORY_INCLUDED__

#define memcpy(dptr,sptr,size) \
  __asm__ __volatile__ ( "rep; movsb" : : "S" ((sptr)), "D" ((dptr)), "c" ((size)) : "memory" ); 

#define memsetb(dptr,b,size) \
  __asm__ __volatile__ ( "rep; stosb" : : "D" ((dptr)), "a" ((unsigned char)(b)), "c" ((size)) : "memory" ); 

#define memsetw(dptr,w,size) \
  __asm__ __volatile__ ( "rep; stosw" : : "D" ((dptr)), "a" ((unsigned short)(w)), "c" ((size)) : "memory" );

#define memsetd(dptr,d,size) \
  __asm__ __volatile__ ( "rep; stosd" : : "D" ((dptr)), "a" ((unsigned int)(d)), "c" ((size)) : "memory" );

#endif
