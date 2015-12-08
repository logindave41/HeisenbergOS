#ifndef __IOPORTS_INCLUDED__
#define __IOPORTS_INCLUDED__

#define outb(port,data) \
  __asm__ __volatile__ ( \
  "outb %1,%%dx" \
  : : "d" ((unsigned short)(port)), "aN" ((unsigned char)(data)) \
   );

#define outw(port,data) \
  __asm__ __volatile__ ( \
  "outw %1,%%dx" \
  : : "d" ((unsigned short)(port)), "a" ((unsigned short)(data)) \
   );

#define inb(port) \
  ({ unsigned char tmp; \
  \  
    __asm__ __volatile__ ( \
    "inb %%dx,%%al" \
     : "=a" (tmp) : "d" ((unsigned short)(port)) \
      ); \
    tmp; })

#define inw(port) \
  ({ unsigned short tmp; \
  \  
    __asm__ __volatile__ ( \
    "inb %%dx,%%ax" \
     : "=a" (tmp) : "d" ((unsigned short)(port)) \
      ); \
    tmp; })
    
#endif
