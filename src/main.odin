package main

MSB_8: u8 : 0xf0
LSB_8: u8 : 0x0f

import "emulator"
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

    emu := emulator.emulator_new(args[1])
    defer emulator.emulator_delete(&emu)

    emulator.emulator_run(&emu)
}
