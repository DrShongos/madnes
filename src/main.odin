package main

MSB_8: u8 : 0xf0
LSB_8: u8 : 0x0f

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
    if !success {
        fmt.eprintf("Failed to open the specified ROM file.\n")
        os.exit(-1)
    }

    nes := console.console_new()

    // TODO: THIS IS TEMPORARY. IMPLEMENT PROPER ROM READING.
    copy(nes.cpu.memory[console.PROGRAM_ROM_START:], rom_file[0x0010:])
    copy(nes.cpu.memory[console.PROGRAM_ROM_MIRROR:], rom_file[0x0010:])

    for {
        console.console_tick(&nes)
    }
}
