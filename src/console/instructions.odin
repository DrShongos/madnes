package console

import "core:fmt"

import "core:math"

//////////////////////////////////////////////////////////////////
///              HELPER FUNCTIONS                             ///
////////////////////////////////////////////////////////////////
status_check_zero :: proc(cpu: ^CPU, value: u8) {
    if value == 0 {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }
}

status_check_negative :: proc(cpu: ^CPU, value: u8) {
    if value & 0b10000000 != 0 {
        cpu.status += {.Negative}
    } else {
        cpu.status -= {.Negative}
    }
}

fetch_zero_page :: proc(cpu: ^CPU) -> u16 {
    lo := cpu_fetch(cpu)

    return bytes_to_address(0x00, lo)
}

fetch_absolute :: proc(cpu: ^CPU) -> u16 {
    hi := cpu_fetch(cpu)
    lo := cpu_fetch(cpu)

    return bytes_to_address(hi, lo)
}

fetch_zero_page_indexed :: proc(cpu: ^CPU, register: u8) -> u16 {
    lo := cpu_fetch(cpu)

    return bytes_to_address(0x00, lo + register)
}

fetch_absolute_indexed :: proc(cpu: ^CPU, register: u8) -> u16 {
    hi := cpu_fetch(cpu)
    lo := cpu_fetch(cpu)

    // Check whether the calculation will cause the high byte to change,
    // triggering a page cross.
    new_lo := lo + register
    if new_lo < lo {
        hi += 0x01
        cpu.page_crossed = true
    }

    return bytes_to_address(hi, new_lo)
}

//////////////////////////////////////////////////////////////////
///                   INSTRUCTIONS                            ///
////////////////////////////////////////////////////////////////
invalid_instruction: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    fmt.eprintf(
        "ERROR: Unknown opcode %x. Possibly unimplemented by the emulator. \n",
        cpu_mem_read(cpu, cpu.program_counter),
    )
    return 255
}

jmp :: proc(cpu: ^CPU, address: u16) {
    hi, lo := address_to_bytes(address)

    // In the real 6502, there is a bug related to the JMP instruction where
    // Trying to set the program counter to the end of a page (0xXXff)
    // Ends up with the CPU failing to increment the value, causing the PC
    // To jump to the start of the address page (0xXX00)
    if lo == 0xff {
        cpu.program_counter = bytes_to_address(hi, 0x00)
        return
    }

    cpu.program_counter = address
}

jmp_absolute: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    jmp(cpu, fetch_absolute(cpu))

    return 3
}

ldx :: proc(cpu: ^CPU, value: u8) {
    cpu.reg_x = value

    status_check_zero(cpu, value)
    status_check_negative(cpu, value)

    cpu.program_counter += 1
}

ldx_immediate: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    arg := cpu_fetch(cpu)
    ldx(cpu, arg)

    return 2
}

ldx_zero_page: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    arg := cpu_mem_read(cpu, fetch_zero_page(cpu))
    ldx(cpu, arg)

    return 3
}

ldx_zero_page_y: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    arg := cpu_mem_read(cpu, fetch_zero_page_indexed(cpu, cpu.reg_y))
    ldx(cpu, arg)

    return 4
}

ldx_absolute: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    arg := cpu_mem_read(cpu, fetch_absolute(cpu))
    ldx(cpu, arg)

    return 4
}

ldx_absolute_y: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    arg := cpu_mem_read(cpu, fetch_absolute_indexed(cpu, cpu.reg_y))
    ldx(cpu, arg)

    return 4
}
