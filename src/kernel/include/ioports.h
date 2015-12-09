#ifndef __IOPORTS_INCLUDED__
#define __IOPORTS_INCLUDED__

#define outb(port,data) \
  __asm__ __volatile__ ( \
    "outb %%al,%0" \
    : : "dN" ((unsigned short)(port)), "a" ((unsigned char)(data)) \
   );

#define outw(port,data) \
  __asm__ __volatile__ ( \
    "outw %%ax,%0" \
    : : "dN" ((unsigned short)(port)), "a" ((unsigned short)(data)) \
   );

unsigned char inline inb(unsigned short port)
{
  unsigned char tmp;

  __asm__ __volatile__ (
    "inb %1,%%al"
     : "=a" (tmp) : "dN" (port)
  );

  return tmp; 
}

unsigned short inline inw(unsigned short port)
{ 
  unsigned short tmp;

  __asm__ __volatile__ (
    "inw %1,%%ax"
     : "=a" (tmp) : "dN" (port)
  );

  return tmp; 
}
    
#endif
