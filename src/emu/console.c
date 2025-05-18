#include "console.h"
#include <corecrt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/// Reads memory from specified address, in compliance with mirroring and
/// registers.
u8 console_read_memory(struct console *console, u16 address)
{
    // Internal RAM
    if (address >= 0x0000 && address <= 0x07FF)
        return console->cpu.internal_memory[address];

    // Internal RAM Mirror 1
    if (address >= 0x0800 && address <= 0x0FFF)
        return console->cpu.internal_memory[address - 0x0800];

    // Internal RAM Mirror 2
    if (address >= 0x1000 && address <= 0x17FF)
        return console->cpu.internal_memory[address - 0x1000];

    if (address >= 0x1800 && address <= 0x1FFF)
        return console->cpu.internal_memory[address - 0x1800];

    // Cartridge data
    return console->cpu.internal_memory[address]; // TODO: Implement mappers and
                                                  // read their memory instead.
}

/// Writes memory into specified address, in compliance with mirroring and
/// registers.
void console_write_memory(struct console *console, u16 address, u8 value)
{
    // Internal RAM
    if (address >= 0x0000 && address <= 0x07FF)
        console->cpu.internal_memory[address] = value;

    // Internal RAM Mirror 1
    if (address >= 0x0800 && address <= 0x0FFF)
        console->cpu.internal_memory[address - 0x0800] = value;

    // Internal RAM Mirror 2
    if (address >= 0x1000 && address <= 0x17FF)
        console->cpu.internal_memory[address - 0x1000] = value;

    if (address >= 0x1800 && address <= 0x1FFF)
        console->cpu.internal_memory[address - 0x1800] = value;

    // Cartridge data
    console->cpu.internal_memory[address] =
        value; // TODO: Implement mappers and
               // write into their memory instead.
}

// TODO: Implement the iNES2.0 format once all official instructions are
// implemented. Loads the test rom with only CPU instructions.
int console_load_test_rom(struct console *console, char *path)
{
    FILE *file;
    errno_t err = fopen_s(&file, path, "rb");
    if (err != 0)
        return 1;

    if (file != NULL) {
        // Get file size
        fseek(file, 0, SEEK_END);
        u64 rom_size = ftell(file);
        fseek(file, 0, SEEK_SET);

        // Read all the data into the buffer.
        char *buffer = (char *)malloc(rom_size);
        fread(buffer, sizeof(u8), rom_size, file);

        fclose(file);

        // Paste PRG ROM data into CPU memory and mirror it, ignoring the header
        // and other data.
        memcpy(console->cpu.internal_memory + 0x8000, buffer + 0x010, 0x4000);
        memcpy(console->cpu.internal_memory + 0xC000, buffer + 0x010, 0x4000);

        // Cleanup
        free(buffer);
    }

    return 0;
}

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
