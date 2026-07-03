#ifndef PICOGK_FLOAT_BITS_H
#define PICOGK_FLOAT_BITS_H

#include <stdint.h>

int32_t picogk_float_to_bits(float f);
float picogk_float_from_bits(int32_t bits);

#endif