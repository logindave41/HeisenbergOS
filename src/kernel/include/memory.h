#ifndef __MEMORY_INCLUDED__
#define __MEMORY_INCLUDED__

#define memcpy(dptr,sptr,size) \
  __asm__ __volatile__ \
    ( "rep; movsb" \
      : : "S" ((sptr)), "D" ((dptr)), "c" ((size)) ); 

#define memsetb(dptr,byte,size) \
  __asm__ __volatile__ \
    ( "rep; stosb" \
      : : "D" ((dptr)), "a" ((unsigned char)(byte)), "c" ((size)) ); 

#define memsetw(dptr,word,size) \
  __asm__ __volatile__ \
    ( "rep; stosw" \
      : : "D" ((dptr)), "a" ((unsigned short)(word)), "c" ((size)) );

#define memsetd(dptr,dword,size) \
  __asm__ __volatile__ \
    ( "rep; stosd" \
      : : "D" ((dptr)), "a" ((unsigned int)(dword)), "c" ((size)) );

#endif
