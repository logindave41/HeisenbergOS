#ifndef __IOPORTS_INCLUDED__
#define __IOPORTS_INCLUDED__

void inline outb(unsigned short port, unsigned char data)
{
  __asm__ __volatile__ (
    "outb %%al,%0"
    : : "dN" (port), "a" (data)
      );
}

void inline outw(unsigned short port, unsigned short data)
{
  __asm__ __volatile__ (
    "outw %%ax,%0"
    : : "dN" (port), "a" (data)
      );
}

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
