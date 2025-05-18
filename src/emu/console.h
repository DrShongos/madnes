#pragma once

#include "../common.h"

#include "cpu.h"

struct console {
    struct processor cpu;  
};

struct bytes {
  u8 hi;
  u8 lo;
};

u8 console_read_memory(struct console* console, u16 address);
void console_write_memory(struct console* console, u16 address, u8 value);

u16 bytes_to_word(u8 hi, u8 lo);
struct bytes word_to_bytes(u16 word);

int console_load_test_rom(struct console* console, char* path);
