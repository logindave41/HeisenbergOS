#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char buffer[8192];

extern short crc_asm(char *, size_t);

short crc(char *p, size_t size)
{
  short sum = 0;
  while (size--)
    sum += *p++;
  return ~sum;
}

void main(void)
{
  short crc1, crc2;

  memset(buffer, 0xff, 8192);
  crc1 = crc(buffer, 8192);
  crc2 = crc_asm(buffer, 8192);

  printf("CRC1 = 0x%hx, CRC2 = 0x%hx\n", crc1, crc2);
}
