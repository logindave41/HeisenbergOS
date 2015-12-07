; ELF32 file header.
struc elf_header
  .magic:       resb  1         ; 0x7f
  .signature:   resb  3         ; "ELF"
  .class:       resb  1         ; 1 = 32 bits, 2 = 64 bits.
  .data         resb  1         ; 1 = little endian
  .version:     resb  1
  .abi_version: resb  1  
  .unused0:     resb  7
  .e_type:      resw  1         ; 1,2,3 or 4.
  .machine:     resw  1         ; 0x03 = i386, 0x3E = x86-64
  .e_version:   resd  1         ; 1
  .e_entry:     resd  1         ; i386 entry point (if x86-64 then resq).
  .e_phoff:     resd  1         ; program header table ptr (if x86_64 then resq).
  .e_shoff:     resd  1         ; section header table ptr (if x86_64 then resq).
  .e_flags:     resd  1
  .eh_size:     resw  1         ; sizeof this header.
  .phentsize:   resw  1         ; program header table entry size.
  .phnum:       resw  1         ; program header table number of entries.
  .shentsize:   resw  1         ; section header table size.
  .shnum:       resw  1         ; section header table number of entries.
  .shstrndx:    resw  1
endstruc


