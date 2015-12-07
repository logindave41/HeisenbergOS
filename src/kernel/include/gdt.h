#ifndef __GDT_INCLUDED__
#define __GDT_INCLUDED__

#define DPL(n)    (((n) & 0x3) << 12)

struct gdt_entry {
  unsigned short limit0;        /* 16 */
  unsigned int   base0:24;      /* 24 */
  unsigned char  attrib0;       /* 8 */
  unsigned char  limit1:4;      /* 4 */
  unsigned char  attrib1:4;     /* 4 */
  unsigned char  base1;         /* 8 */
} __attribute__((packed));

void inline set_limit(struct gdt_entry * pgdt_entry, unsigned int limit)
{
  pgdt_entry->limit0 = limit;
  pgdt_entry->limit1 = limit >> 16;
}

void inline set_base(struct gdt_entry * pgdt_entry, unsigned int base)
{
  pgdt_entry->base0 = base;
  pgdt_entry->base1 = base >> 16;
}

void inline set_attribute(struct gdt_entry * pgdt_entry, unsigned short attrib)
{
  pgdt_entry->attrib0 = attrib;
  pgdt_entry->attrib1 = attrib >> 8;  
}

#endif
