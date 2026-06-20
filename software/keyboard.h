#ifndef __KEY_ID_H_
#define __KEY_ID_H_

#include <altera_avalon_pio_regs.h>

#define KEY_0           0x00000001
#define KEY_N1          0x00000002
#define KEY_N2          0x00000004
#define KEY_N3          0x00000008
#define KEY_N4          0x00000010
#define KEY_N5          0x00000020
#define KEY_N6          0x00000040
#define KEY_N7          0x00000080
#define KEY_N8          0x00000100
#define KEY_N9          0x00000200
#define KEY_A           0x00000400
#define KEY_B           0x00000800
#define KEY_C           0x00001000
#define KEY_D           0x00002000
#define KEY_E           0x00004000
#define KEY_F           0x00008000
#define KEY_G           0x00010000
#define KEY_H           0x00020000
#define KEY_I           0x00040000
#define KEY_J           0x00080000
#define KEY_K           0x00100000
#define KEY_L           0x00200000
#define KEY_M           0x00400000
#define KEY_N           0x00800000
#define KEY_O           0x01000000
#define KEY_P           0x02000000
#define KEY_Q           0x04000000
#define KEY_R           0x08000000
#define KEY_S           0x10000000
#define KEY_T           0x20000000
#define KEY_U           0x40000000
#define KEY_V           0x80000000
#define KEY_W           0x00000001
#define KEY_X           0x00000002
#define KEY_Y           0x00000004
#define KEY_Z           0x00000008
#define KEY_ESC         0x00000010
#define KEY_ENTER       0x00000020
#define KEY_SPACE       0x00000040
#define KEY_CONTROL     0x00000080
#define KEY_SHIFT       0x00000100
#define KEY_LEFT_ARROW  0x00000200
#define KEY_UP_ARROW    0x00000400
#define KEY_RIGHT_ARROW 0x00000800
#define KEY_DOWN_ARROW  0x00001000

uint8_t getKeyboard(uint32_t KEY_BASE, uint32_t KEY) {

    return (IORD_ALTERA_AVALON_PIO_DATA(KEY_BASE) & KEY)?0x01:0x00;
}

#endif