/* Rotinas de vídeo da nossa "BIOS". */
#include <ioports.h>
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

void __attribute__((noinline,regparm(2))) gotoxy(unsigned char x, unsigned char y)
{
  if (x > SCREEN_WIDTH) x = SCREEN_WIDTH - 1;
  if (y > SCREEN_HEIGHT) y = SCREEN_HEIGHT - 1;
  UCHAR_VAR(screen_x) = x;
  UCHAR_VAR(screen_y) = y;
}

void __attribute__((noinline)) scroll_up(void)
{
  void *srcptr, *destptr;

  destptr = (srcptr = VIDEO_BUFFER_PTR) + SCREEN_WIDTH*2;
  memcpy(destptr, srcptr, (SCREEN_HEIGHT - 1)*SCREEN_WIDTH*2);
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

/******************************************** 
 * Função para leitura de setores do disco.
 * Usa PIO-ATA, sem uso de UDMA ou IRQs, fazendo pooling. 
 *********************************************/
#define HDD_DRIVE_HEAD_MASK     0xA0
#define HDD_DRIVE_HEAD_LBA      0x40
#define HDD_DRIVE_HEAD_DISK0    0x00
#define HDD_DRIVE_HEAD_DISK1    0x10
#define HDD_DRIVE_HEAD_HMASK    0x0f

#define HDD_STATUS_EXECUTING    0x80
#define HDD_STATUS_DRIVEREADY   0x40
#define HDD_STATUS_WRITEFAULT   0x20
#define HDD_STATUS_SEEKCOMPLETE 0x10
#define HDD_STATUS_SECTBUFFERR  0x08
#define HDD_STATUS_READCORRECTED 0x04
#define HDD_STATUS_INDEX        0x02
#define HDD_STATUS_CMDERROR     0x01

#define HDD_CMD_READWORETRY     0x21

#define HDC0_BASE_PORT          0x1f0
#define HDC1_BASE_PORT          0x170

#define HDC_DATA_PORT(x)          (x)
#define HDC_ERROR_PORT(x)         ((x) + 1)
#define HDC_SECTOR_COUNT_PORT(x)  ((x) + 2)
#define HDC_SECTOR_PORT(x)        ((x) + 3)
#define HDC_CYLINDER_LOW_PORT(x)  ((x) + 4)
#define HDC_CYLINDER_HI_PORT(x)   ((x) + 5)
#define HDC_DRIVE_HEAD_PORT(x)    ((x) + 6)
#define HDC_STATUS_PORT(x)        ((x) + 7)

unsigned short __attribute__((regparm(1))) select_hdc(unsigned char drive_no)
{
  if (drive_no >= 0x80)
  {
    unsigned short port;

    switch (drive_no & 3)
    {
      case 0:
      case 1:
        port = HDC0_BASE_PORT;
        break;
      case 2:
      case 3:
        port = HDC1_BASE_PORT;
    }

    return port;
  }
  return 0;
}

void __attribute__((regparm(3))) read_sectors(unsigned char drive_no, 
                                              void *buffer,   /* Normalizado! */
                                              unsigned short cylinder, 
                                              unsigned char sector,
                                              unsigned char head,
                                              unsigned char sectors)
{
  unsigned short port;
  unsigned int buffer_size;

  port = select_hdc(drive_no);
  buffer_size = sectors * 512;
  
  /* Continua aqui */
}
