package console

import "../formats"
import "./mappers"

PPU_WARMUP_CYCLE :: 29658

Console :: struct {
    cpu:    CPU,
    ppu:    PPU,
    mapper: mappers.NROM, // TODO: Implement Mapper interface to support multiple cartridge types
}

console_new :: proc() -> Console {
    console := Console {
        cpu = cpu_new(),
        ppu = ppu_new(),
    }
    console.cpu.console = &console

    return console
}

console_delete :: proc(console: ^Console) {
    mappers.nrom_remove(&console.mapper)
}

// Loads the cartridge and resets the CPU to load the program counter
// from the reset vector.
console_load_cartridge :: proc(
    console: ^Console,
    file: ^formats.NES2_0_Format,
) {
    console.mapper = mappers.nrom_from_nes2(file)
    console.cpu.console = console
    pc_lo := cpu_mem_read(&console.cpu, 0xfffc)

    console.cpu.total_cycles += 1
    pc_hi := cpu_mem_read(&console.cpu, 0xfffd)
    console.cpu.total_cycles += 1

    pc_start := bytes_to_address(pc_lo, pc_hi)
    console.cpu.program_counter = pc_start
    console.cpu.total_cycles += 2
}

console_tick :: proc(console: ^Console) {
    cpu_tick(&console.cpu)

    if console.ppu.initialized {
        for _ in 0 ..< console.cpu.cycle {
            // The PPU ticks 3 times for each CPU cycle
            ppu_tick(&console.ppu)
            ppu_tick(&console.ppu)
            ppu_tick(&console.ppu)
        }
    }

    if console.cpu.total_cycles >= PPU_WARMUP_CYCLE {
        ppu_init(&console.ppu)
    }
}
