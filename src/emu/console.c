#include "console.h"

u8 console_read_memory(struct console *console, u16 address) {}

void console_write_memory(struct console *console, u16 address, u8 value) {}

u16 bytes_to_word(u8 hi, u8 lo)
{
    u16 _hi = hi;
    u16 _lo = lo;

    return _hi | (_lo << 8);
}

struct bytes word_to_bytes(u16 word)
{
    struct bytes bytes;
    bytes.hi = word & 0xFF;
    bytes.lo = word >> 8;

    return bytes;
}
