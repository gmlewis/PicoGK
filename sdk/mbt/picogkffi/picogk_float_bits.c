// C helper for reinterpreting float bits as int32 and vice versa.
// This avoids relying on MoonBit Float methods that may not exist.

#include <stdint.h>
#include <string.h>

// Reinterpret float bits as int32 (for serialization)
int32_t picogk_float_to_bits(float f) {
    int32_t bits;
    memcpy(&bits, &f, sizeof(bits));
    return bits;
}

// Reinterpret int32 bits as float (for deserialization)
float picogk_float_from_bits(int32_t bits) {
    float f;
    memcpy(&f, &bits, sizeof(f));
    return f;
}