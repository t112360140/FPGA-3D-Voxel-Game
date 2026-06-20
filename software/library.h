#ifndef _LIB_H_
#define _LIB_H_

#include <stdint.h>

volatile uint16_t *cos_table_ptr = (volatile uint16_t *) (COS_TABLE_BASE | 0x80000000);

static inline int32_t cos_t(uint16_t x) {
	x = x % 1024;

    uint16_t idx;
    if (x < 256) idx = x;
    else if (x < 512) idx = 512 - x;
    else if (x < 768) idx = x - 512;
    else idx = 1024 - x;

    int32_t base_val = (idx == 0) ? 0x10000 : (int32_t)cos_table_ptr[idx];

    if (x >= 256 && x < 768) {
        return -base_val;
    }
    return base_val;
}

static inline int32_t sin_t(uint16_t x) {
    return cos_t(x - 256);
}

static inline int32_t abs_t(int32_t x) {
	return x>=0?x:-x;
}


volatile uint32_t lfsr32 = 0xAC0140EC;
static inline void rand32_init(uint32_t seed){
    if(seed==0) lfsr32=0xAC0140EC;
    else lfsr32 = seed;
}
static inline uint32_t rand32() {
    uint8_t lsb = lfsr32 & 1;
    lfsr32 >>= 1;
    if (lsb) {
        lfsr32 ^= 0x80000057;
    }
    return lfsr32;
}

#endif
