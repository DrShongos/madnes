package console

import "core:fmt"
import "core:os"

Interrupt :: enum {
    IRQ,
    NMI,
}

Console :: struct {
    cpu:    CPU,
    ppu:    PPU,
    mapper: Mapper,
}

init_console :: proc() -> Console {
    console := Console{}
    console.cpu = init_cpu()
    console.ppu = PPU{}

    return console
}

console_tick :: proc(console: ^Console) {
    run_cycle(&console.cpu, console)
    if console.cpu.cycle == 255 {
        os.exit(-1)
    }

    if !console.ppu.initialized && console.cpu.executed_cycles >= 29658 {
        init_ppu(&console.ppu)
    }
}

trigger_interrupt :: proc(console: ^Console, interrupt: Interrupt) {
    switch interrupt {
    case Interrupt.IRQ:
        prev_pc_hi, prev_pc_low := u16_to_u8(console.cpu.program_counter)
        stack_push(&console.cpu, prev_pc_low)
        stack_push(&console.cpu, prev_pc_hi)

        console.cpu.status += {.Break}

        irq_hi := read_memory(&console.cpu, console, 0xFFFE)
        irq_lo := read_memory(&console.cpu, console, 0xFFFF)

        irq_vector := u8_to_u16(irq_hi, irq_lo)
        console.cpu.program_counter = irq_vector
    case Interrupt.NMI:
    }
}

load_prg_rom :: proc(console: ^Console, prg: []u8) {
    // The PRG ROM is loaded twice until mappers will be implemented
    copy(console.cpu.memory[PRG_ROM_START:], prg)
    copy(console.cpu.memory[PRG_ROM_MIRROR:], prg)
}


u16_to_u8 :: proc(word: u16) -> (u8, u8) {
    hi := (word & 0xFF)
    lo := word >> 8

    return u8(hi), u8(lo)
}

u8_to_u16 :: proc(hi: u8, lo: u8) -> u16 {
    hi := u16(hi)
    lo := u16(lo)
    word: u16 = u16(hi | (lo << 8))
    return word
}
