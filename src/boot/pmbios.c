/* Rotinas de vídeo da nossa "BIOS". */
#include <memory.h>
#include "vars.h"

/*********************
 * Funções relacionadas ao vídeo.
 *********************/

/* Isso é válido para o modo 2 */
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
  UCHAR_VAR(screen_x) = x;
  UCHAR_VAR(screen_y) = y;
}

void __attribute__((noinline)) scroll_up(void)
{
  memcpy(VIDEO_BUFFER_PTR, VIDEO_PTR(0,1), (SCREEN_HEIGHT - 1)*SCREEN_WIDTH*2);
  memsetw(VIDEO_PTR(0,24), ((unsigned short)UCHAR_VAR(screen_attrib) << 8) | ' ', SCREEN_WIDTH);
}

void __attribute__((regparm(1))) settext_attribute(unsigned char attrib)
{
  UCHAR_VAR(screen_attrib) = attrib;
}

unsigned char __attribute__((noinline)) gettext_attribute(void)
{
  return UCHAR_VAR(screen_attrib);
}

void __attribute__((noinline)) clearscreen(void)
{
  memsetw(VIDEO_BUFFER_PTR, 
          ((unsigned short)UCHAR_VAR(screen_attrib) << 8) | ' ', 
          SCREEN_WIDTH*SCREEN_HEIGHT);
  gotoxy(0,0);
}

void __attribute__((noinline,regparm(1))) putch(unsigned char c)
{
  unsigned char sx, sy;

  sx = UCHAR_VAR(screen_x);
  sy = UCHAR_VAR(screen_y);
  switch (c)
  {
    case '\r':
    test_scroll:
      if (++sy >= SCREEN_HEIGHT)
      {
        scroll_up();
        gotoxy(sx, sy = SCREEN_HEIGHT - 1);
      }
      break;

    case '\n':
      gotoxy(sx = 0, sy);
      break;

    default:
     *((unsigned short *)VIDEO_PTR(sx++, sy)) = 
          ((unsigned short)UCHAR_VAR(screen_attrib) << 8) | c;
     if (sx >= SCREEN_WIDTH)
     {
      sx = 0;
      goto test_scroll;
     }
  }

  UCHAR_VAR(screen_x) = sx;
  UCHAR_VAR(screen_y) = sy;
}

