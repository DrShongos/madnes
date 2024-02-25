package console

import "core:math"

PC_NESTEST_START :: 0xC000

PRG_ROM_START :: 0x8000
PRG_ROM_MIRROR :: 0xC000
OPCODE_TABLE_SIZE :: 256
STACK_TOP :: 0xFD

Processor_Status_Flags :: enum {
    Negative          = 7,
    Overflow          = 6,
    // This bit is always 1 because it just is, okay???
    Always_1          = 5,
    Break             = 4,
    // Ignored by NES
    Decimal_Mode      = 3,
    Interrupt_Disable = 2,
    Zero              = 1,
    Carry             = 0,
}

Processor_Status :: bit_set[Processor_Status_Flags]

CPU :: struct {
    status:          Processor_Status,
    accumulator:     u8,
    register_x:      u8,
    register_y:      u8,
    stack_top:       u8,
    program_counter: u16,
    memory:          [0xFFFF + 1]u8,
    memory_bus: ^Memory_Bus,

    // Opcode execution
    cycle:           u8,
    opcode_table:    [OPCODE_TABLE_SIZE]Opcode,
    page_crossed:    bool,
    executed_cycles: u64,
}

init_cpu :: proc() -> CPU {
    cpu := CPU {
        status          = transmute(Processor_Status)u8(0x24),
        accumulator     = 0,
        register_x      = 0,
        register_y      = 0,
        stack_top       = STACK_TOP,
        program_counter = 0x8000,
        cycle           = 0,
        opcode_table    = create_opcode_table(),
        page_crossed    = false,
        executed_cycles = 7,
    }

    for i := 0; i < 0xFFFF; i += 1 {
        cpu.memory[i] = 0
    }

    return cpu
}

/// Increments the program counter and fetches the next byte
cpu_fetch :: proc(cpu: ^CPU) -> u8 {
    cpu.program_counter += 1
    return cpu.memory[cpu.program_counter]
}

stack_push :: proc(cpu: ^CPU, val: u8) {
    cpu.memory[cpu.stack_top] = val
    cpu.stack_top -= 1
}

stack_pop :: proc(cpu: ^CPU) -> u8 {
    cpu.stack_top += 1
    return cpu.memory[cpu.stack_top]
}

run_cycle :: proc(cpu: ^CPU) {
    cpu.page_crossed = false
    code := cpu.memory[cpu.program_counter]
    opcode := cpu.opcode_table[code]
    cpu.cycle = execute_opcode(&opcode, cpu)
    if cpu.page_crossed {
        cpu.cycle += 1
    }
    cpu.executed_cycles += u64(cpu.cycle)
    //cpu.program_counter += 1
}
