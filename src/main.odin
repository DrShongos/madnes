package madnes

import "core:fmt"
import "core:os"

import "console"
import "rom_formats"

main :: proc() {
    nestest_file, success := os.read_entire_file_from_filename("nestest.nes")
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

    emulated := console.init_console()
    console.load_prg_rom(&emulated, test_rom.prg_rom)

    emulated.cpu.program_counter = console.PC_NESTEST_START
    console.run_console(&emulated)
}

print_bytes :: proc(bytes: []byte) {
    for data in bytes {
        fmt.printf("%d ", data)
    }
    fmt.printf("\n")
}
