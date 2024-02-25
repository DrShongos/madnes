package madnes

import "core:fmt"
import "core:os"

import "emulator"
import "console"
import "rom_formats"

main :: proc() {
    args := os.args

    if len(args) < 2 {
        fmt.printf("Please specify a ROM file \n");
        os.exit(-1)
    }

    nestest_file, success := os.read_entire_file_from_filename(args[1])
    if !success {
        fmt.printf("COULD NOT OPEN FILE\n")
        os.exit(-1)
    }

    test_rom, err := rom_formats.parse_ines_file(nestest_file)
    defer rom_formats.delete_ines_file(&test_rom)

    if err != .None {
        fmt.printf("An error occured while parsing an INES file \n")
        os.exit(-1)
    }

    emu := emulator.init_emulator()
    console.load_prg_rom(&emu.console, test_rom.prg_rom)

    emu.console.cpu.program_counter = console.u8_to_u16(emu.console.cpu.memory[0xFFFC], emu.console.cpu.memory[0xFFFD])

    emulator.run_emulator(&emu)
}

print_bytes :: proc(bytes: []byte) {
    for data in bytes {
        fmt.printf("%d ", data)
    }
    fmt.printf("\n")
}
