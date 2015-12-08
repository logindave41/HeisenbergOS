/* Rotinas de vídeo da nossa "BIOS". */
#include <memory.h>

#define VIDEO_BUFFER_PTR  (void *)0xb8000
#define SCREEN_WIDTH  80
#define SCREEN_HEIGHT 25
#define VIDEO_PTR(x,y) (VIDEO_BUFFER_PTR + ((y) * SCREEN_WIDTH * 2) + (x)*2)

static unsigned char screen_x = 0, screen_y = 1;
static unsigned char screen_attrib = 7;

/* x é passado em AL, y em DL. */
void __attribute__((noinline,regparm(2))) gotoxy(unsigned char x, unsigned char y)
{
  if (x > SCREEN_WIDTH) x = SCREEN_WIDTH - 1;
  if (y > SCREEN_HEIGHT) y = SCREEN_HEIGHT - 1;
  screen_x = x;
  screen_y = y;
}

void __attribute__((noinline)) scroll_up(void)
{
  memcpy(VIDEO_BUFFER_PTR, VIDEO_PTR(0,1), (SCREEN_HEIGHT - 1)*SCREEN_WIDTH*2);
  memsetw(VIDEO_PTR(0,24), ((unsigned short)screen_attrib << 8) | ' ', SCREEN_WIDTH);
}

void __attribute__((regparm(1))) settext_attribute(unsigned char attrib)
{
  screen_attrib = attrib;
}

unsigned char __attribute__((noinline)) gettext_attribute(void)
{
  return screen_attrib;
}

void __attribute__((noinline)) clearscreen(void)
{
  memsetw(VIDEO_BUFFER_PTR, ((unsigned short)screen_attrib << 8) | ' ', SCREEN_WIDTH*SCREEN_HEIGHT);
  gotoxy(0,0);
}

void __attribute__((noinline,regparm(1))) putch(unsigned char c)
{
  switch (c)
  {
    case '\r':
    test_scroll:
      if (++screen_y >= SCREEN_HEIGHT)
      {
        scroll_up();
        gotoxy(screen_x, screen_y = SCREEN_HEIGHT - 1);
      }
      break;

    case '\n':
      gotoxy(screen_x = 0, screen_y);
      break;

    default:
     *((unsigned short *)VIDEO_PTR(screen_x++, screen_y)) = ((unsigned short)screen_attrib << 8) | c;
     if (screen_x >= SCREEN_WIDTH)
     {
      screen_x = 0;
      goto test_scroll;
     }
  }
}
