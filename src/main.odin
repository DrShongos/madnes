package main

MSB_8: u8 : 0xf0
LSB_8: u8 : 0x0f

import "formats"

import "console"
import "core:fmt"
import "core:os"

main :: proc() {
    args := os.args

    if len(args) < 2 {
        fmt.eprintf("Please specify a ROM file.\n")
        os.exit(-1)
    }

    rom_file, success := os.read_entire_file_from_filename(args[1])
    defer delete(rom_file)

    if !success {
        fmt.eprintf("Failed to open the specified ROM file.\n")
        os.exit(-1)
    }

    nes := console.console_new()
    defer console.console_delete(&nes)

    ines_format := formats.nes2_0_parse(rom_file)
    console.console_load_cartridge(&nes, &ines_format)

    for {
        console.console_tick(&nes)
    }
}

