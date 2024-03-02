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

    rom_file, success := os.read_entire_file_from_filename(args[1])
    if !success {
        fmt.printf("COULD NOT OPEN FILE\n")
        os.exit(-1)
    }

    rom, err := rom_formats.load_rom(rom_file, rom_formats.Target_Format.INES)

    if rom_formats.error_occured(err) {
        fmt.printf("An error occured while parsing an INES file \n")
        fmt.println("Err: ", err)
        os.exit(-1)
    }

    emu := emulator.init_emulator()

    mapper, mapper_err := rom_formats.init_mapper(&rom)
    if rom_formats.error_occured(err) {
        fmt.println("An error occured while preparing the mapper")
        fmt.println(err)
        os.exit(-1)
    }
    emu.console.mapper = mapper
    //fmt.println(mapper)

    // TODO because I forgot: THIS SHOULD BE READ FROM THE MAPPER INSTEAD!!!!!!!!!!!!!!!!!
    emu.console.cpu.program_counter = console.u8_to_u16(
        console.read_memory(&emu.console.cpu, &emu.console, 0xFFFC), //emu.console.cpu.memory[0xFFFC],//emu.console.cpu.memory[0xFFFD],
        console.read_memory(&emu.console.cpu, &emu.console, 0xFFFD),
    )

    emulator.run_emulator(&emu)
}
