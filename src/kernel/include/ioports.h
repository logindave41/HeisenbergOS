#ifndef __IOPORTS_INCLUDED__
#define __IOPORTS_INCLUDED__

#define outportb(port, data) \
  __asm__ __volatile__ ( "outb %%al,%%dx" : : "d" ((unsigned char)(port)), "a" ((unsigned char)(data)) )

#define outportw(port, data) \
  __asm__ __volatile__ ("outw %%ax,%%dx" : : "d" ((unsigned short)(port)), "a" ((unsigned short)(data)) )

#define inportb(port) \
  ({ unsigned char tmp; __asm__ __volatile__ ("inb %%dx,%%al" : "=a" (tmp) : "d" ((unsigned short)(port))); tmp; })

#define inportw(port) \
  ({ unsigned short tmp; __asm__ __volatile__ ("inb %%dx,%%ax" : "=a" (tmp) : "d" ((unsigned short)(port))); tmp; })

#endif
