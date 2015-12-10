#ifndef __DEFINES_INCLUDED__
#define __DEFINES_INCLUDED__

/* Atributos usados em funções. */
#define USEREGS __attribute__((noinline,regparm(3)))
#define NOINLINE __attribute__((noinline))

/* Endereço linear do início do kernel. */
#define KERNEL_ENTRY (void *)0x100000U

/*------------------
    Definições e macros para o modo de vídeo 2, inicializado
    por mbr.asm.
  ------------------*/
#define VIDEO_BUFFER_PTR  (void *)0xb8000U

#define SCREEN_WIDTH  80
#define SCREEN_HEIGHT 25

/* Obtem o ponteiro da posição (x,y) da tela. */
#define VIDEO_PTR(x,y) (void *)(VIDEO_BUFFER_PTR + ((y)*SCREEN_WIDTH*2) + (x)*2)

#endif
