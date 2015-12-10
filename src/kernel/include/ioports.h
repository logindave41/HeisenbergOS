#ifndef __IOPORTS_INCLUDED__
#define __IOPORTS_INCLUDED__

#define outportb(port, data) \
  __asm__ __volatile__ ( "outb %%al,%%dx" : : "d" ((unsigned char)(port)), "a" ((data)) )

#define outportw(port, data) \
  __asm__ __volatile__ ("outw %%ax,%%dx" : : "d" ((unsigned short)(port)), "a" ((data)) )

#define inportb(port) \
  ({ unsigned char tmp; __asm__ __volatile__ ("inb %%dx,%%al" : "=a" (tmp) : "d" ((port))); tmp; })

#define inportw(port) \
  ({ unsigned short tmp; __asm__ __volatile__ ("inb %%dx,%%ax" : "=a" (tmp) : "d" ((port))); tmp; })

#endif
