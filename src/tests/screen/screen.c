#define VIDEO_BUFFER_PTR (void *)0xb8000

#define SCREEN_WIDTH  80U
#define SCREEN_HEIGHT 25U

extern unsigned char screen_x;
extern unsigned char screen_y;
extern unsigned char screen_attrib;

extern void memcpy(void *, void *, unsigned int);

void __attribute__((noinline)) gotoxy(unsigned int x, unsigned int y)
{
  if (x >= SCREEN_WIDTH) x = SCREEN_WIDTH - 1;
  if (y >= SCREEN_HEIGHT) y = SCREEN_HEIGHT - 1;
  screen_x = x;
  screen_y = y;
}

void __attribute__((noinline)) putchar(unsigned char c)
{
  unsigned char *p;

  switch (c)
  {
    case '\r':  gotoxy(screen_x, screen_y+1); break;
    case '\n':  gotoxy(0, screen_y); break;
    default:
      p = (unsigned char *)VIDEO_BUFFER_PTR + ((unsigned int)screen_x * 2 + (unsigned int)screen_y * SCREEN_WIDTH*2);
      *p++ = c;
      *p = screen_attrib;
      if (++screen_x >= SCREEN_WIDTH)
      {
        screen_x = 0;
        screen_y++;
      }

      if (screen_y > SCREEN_HEIGHT)
      {
        unsigned size = (screen_y - SCREEN_HEIGHT - 1)*SCREEN_WIDTH;
        unsigned short *p = (unsigned short *)VIDEO_BUFFER_PTR;
        unsigned short *q = p + size;
        unsigned short ca = ((unsigned short)' ' | ((unsigned short)screen_attrib << 8));

        memcpy(p, q, SCREEN_HEIGHT*SCREEN_WIDTH*2 - size);
        p += (SCREEN_HEIGHT - 1)*SCREEN_WIDTH;
        q = p + SCREEN_WIDTH;
        while (p <= q) *p++ = ca;

        screen_y = SCREEN_HEIGHT - 1;
      }      
  }
}
