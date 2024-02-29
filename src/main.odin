package madnes

import "core:fmt"
import "core:os"

import "console"
import "emulator"
import "rom_formats"

main :: proc() {
    args := os.args

    if len(args) < 2 {
        fmt.printf("Please specify a ROM file \n")
        os.exit(-1)
    }

    nestest_file, success := os.read_entire_file_from_filename(args[1])
    if !success {
        fmt.printf("COULD NOT OPEN FILE\n")
        os.exit(-1)
    }

    test_rom, err := rom_formats.load_rom(
        nestest_file,
        rom_formats.Target_Format.INES,
    )

    if rom_formats.error_occured(err) {
        fmt.printf("An error occured while parsing an INES file \n")
        fmt.println("Err: ", err)
        os.exit(-1)
    }

    emu := emulator.init_emulator()

    rom_formats.load_to_console(&emu.console, &test_rom)

    mapper, mapper_err := rom_formats.init_mapper(&test_rom)
    if rom_formats.error_occured(err) {
        fmt.println("An error occured while preparing the mapper")
        fmt.println(err)
        os.exit(-1)
    }
    emu.console.memory_bus.mapper = mapper
    emu.console.cpu.memory_bus = &emu.console.memory_bus
    //fmt.println(mapper)

    // TODO because I forgot: THIS SHOULD BE READ FROM THE MAPPER INSTEAD!!!!!!!!!!!!!!!!!
    emu.console.cpu.program_counter = console.u8_to_u16(
        //emu.console.cpu.memory[0xFFFC],
        //emu.console.cpu.memory[0xFFFD],
        console.read_memory(&emu.console.cpu, 0xFFFC),
        console.read_memory(&emu.console.cpu, 0xFFFD),
    )

    emulator.run_emulator(&emu)
}

print_bytes :: proc(bytes: []byte) {
    for data in bytes {
        fmt.printf("%d ", data)
    }
    fmt.printf("\n")
}
