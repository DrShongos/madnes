package console

import "core:os"
import "core:fmt"

Addressing_Mode :: enum {
    Implied,
    Accumulator,
    Immediate,
    Zero_Page,
    Zero_Page_X,
    Zero_Page_Y,
    Relative,
    Absolute,
    Absolute_X,
    Absolute_Y,
    Indirect,
    Indexed_Indirect,
    Indirect_Indexed
}

Opcode :: struct {
    name: string,
    addressing_mode: Addressing_Mode,
    action: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8
}

create_opcode_table :: proc() -> [OPCODE_TABLE_SIZE]Opcode {
    opcode_table := [OPCODE_TABLE_SIZE]Opcode{}

    for i := 0; i < OPCODE_TABLE_SIZE; i += 1 {
        opcode_table[i] = Opcode {
            name = "INVALID",
            addressing_mode = Addressing_Mode.Implied,
            action = invalid,
        }
    }

    opcode_table[0] = Opcode {
        name = "BRK",
        addressing_mode = Addressing_Mode.Implied,
        action = brk,
    }

    return opcode_table
}

execute_opcode :: proc(opcode: ^Opcode, cpu: ^CPU) -> u8 {
    return opcode.action(cpu, opcode.addressing_mode)
}

invalid :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
    fmt.printf("ERROR: Attempted to execute invalid opcode %x\n", cpu.memory[cpu.program_counter])
    return 255
}

brk :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
    prev_pc_hi, prev_pc_low := u16_to_u8(cpu.program_counter)
    stack_push(cpu, prev_pc_low)
    stack_push(cpu, prev_pc_hi)

    cpu.status += {.Break}
    
    irq_hi := cpu.memory[0xFFFE]
    irq_lo := cpu.memory[0xFFFF]

    irq_vector := u8_to_u16(irq_hi, irq_lo)
    cpu.program_counter = irq_vector
    return 7
}


nop :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
    return 2
}
