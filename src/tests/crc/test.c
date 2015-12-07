#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE   8192

char buffer[BUFFER_SIZE];

extern short cksum_asm(char *, size_t);

short cksum(char *p, size_t size)
{
  unsigned int sum;

  sum = 0;
  while (size--)
    sum += *(unsigned char *)p++;

  if (sum >> 16)
    sum = (sum + (sum >> 16)) & 0xffff;

  return ~sum;
}

void main(void)
{
  short cksum1, cksum2;

  memset(buffer, 0xff, BUFFER_SIZE);
  cksum1 = cksum(buffer, BUFFER_SIZE);
  cksum2 = cksum_asm(buffer, BUFFER_SIZE);

  printf("CRC1 = 0x%hx, CRC2 = 0x%hx\n", 
         cksum1, cksum2);
}
