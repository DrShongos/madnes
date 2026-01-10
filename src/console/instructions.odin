package console

import "core:fmt"
import "core:os"

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

status_check_overflow :: proc(cpu: ^CPU, value: u8) {
    if value & 0b01000000 != 0 {
        cpu.status += {.Overflow}
    } else {
        cpu.status -= {.Overflow}
    }
}

fetch_zero_page :: proc(cpu: ^CPU) -> u16 {
    lo := cpu_fetch(cpu)

    // Consumes an additional cycle
    cpu.cycle += 1

    return bytes_to_address(0x00, lo)
}

fetch_absolute :: proc(cpu: ^CPU) -> u16 {
    hi := cpu_fetch(cpu)
    lo := cpu_fetch(cpu)

    return bytes_to_address(hi, lo)
}

fetch_relative :: proc(cpu: ^CPU) -> u16 {
    offset := u16(cpu_fetch(cpu))
    pc_offset := cpu.program_counter

    // If the offset value would be negative,
    // Reverse the offset block to make the final result wrap around.
    if offset & 0x80 != 0 {
        offset |= 0xff00
    }

    return pc_offset + offset
}

fetch_zero_page_indexed :: proc(cpu: ^CPU, register: u8) -> u16 {
    lo := cpu_fetch(cpu)

    // Consumes additional 2 cycles
    cpu.cycle += 2

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
        cpu.cycle += 1
    }

    return bytes_to_address(hi, new_lo)
}

fetch_address :: proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) -> u16 {
    #partial switch addressing_mode {
    case .Immediate:
        {
            cpu_advance(cpu)
            return cpu.program_counter
        }
    case .Zero_Page:
        return fetch_zero_page(cpu)
    case .Zero_Page_X:
        return fetch_zero_page_indexed(cpu, cpu.reg_x)
    case .Zero_Page_Y:
        return fetch_zero_page_indexed(cpu, cpu.reg_y)
    case .Absolute:
        return fetch_absolute(cpu)
    case .Absolute_X:
        return fetch_absolute_indexed(cpu, cpu.reg_x)
    case .Absolute_Y:
        return fetch_absolute_indexed(cpu, cpu.reg_y)
    case .Relative:
        return fetch_relative(cpu)
    }

    unreachable()
}

//////////////////////////////////////////////////////////////////
///                   INSTRUCTIONS                            ///
////////////////////////////////////////////////////////////////
invalid_instruction: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    fmt.eprintf(
        "ERROR: Unknown opcode %x. Possibly unimplemented by the emulator. \n",
        cpu_mem_read(cpu, cpu.program_counter),
    )

    os.exit(-1)
}

jmp: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
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
    cpu.cycle += 1
}

jsr: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)

    // Pushes the program counter that would lead to the next instruction to the stack.
    return_pc := cpu.program_counter
    pc_hi, pc_lo := address_to_bytes(return_pc)

    stack_push(cpu, pc_hi)
    cpu.cycle += 1

    stack_push(cpu, pc_lo)
    cpu.cycle += 1

    cpu.program_counter = address
    cpu.cycle += 2
}

rts: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    pc_lo := stack_pop(cpu)
    cpu.cycle += 1

    pc_hi := stack_pop(cpu)
    cpu.cycle += 1

    cpu.program_counter = bytes_to_address(pc_hi, pc_lo)
    cpu.cycle += 3

    cpu_advance(cpu)
}

ldx: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    value := cpu_mem_read(cpu, address)
    cpu.reg_x = value

    status_check_zero(cpu, value)
    status_check_negative(cpu, value)

    cpu_advance(cpu)
}

lda: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    value := cpu_mem_read(cpu, address)
    cpu.accumulator = value

    status_check_zero(cpu, value)
    status_check_negative(cpu, value)

    cpu_advance(cpu)
}

stx: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    cpu_mem_write(cpu, address, cpu.reg_x)

    cpu_advance(cpu)
}

sta: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    cpu_mem_write(cpu, address, cpu.accumulator)

    cpu_advance(cpu)
}

nop: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu.cycle += 1
    cpu_advance(cpu)
}

sec: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu.status += {.Carry}
    cpu.cycle += 1

    cpu_advance(cpu)
}

clc: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu.status -= {.Carry}
    cpu.cycle += 1

    cpu_advance(cpu)
}

bcs: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    if .Carry in cpu.status {
        new_pc := fetch_relative(cpu)

        // Check for page crossing
        if new_pc & 0xff00 != cpu.program_counter {
            cpu.cycle += 1
        }
        cpu.program_counter = new_pc
    } else {
        // Skip the argument
        cpu_advance(cpu)
    }

    cpu_advance(cpu)
}

bcc: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    if .Carry not_in cpu.status {
        new_pc := fetch_relative(cpu)

        // Check for page crossing
        if new_pc & 0xff00 != cpu.program_counter {
            cpu.cycle += 1
        }
        cpu.program_counter = new_pc
    } else {
        // Skip the argument
        cpu_advance(cpu)
    }

    cpu_advance(cpu)
}

beq: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    if .Zero in cpu.status {
        new_pc := fetch_relative(cpu)

        // Check for page crossing
        if new_pc & 0xff00 != cpu.program_counter {
            cpu.cycle += 1
        }
        cpu.program_counter = new_pc
    } else {
        // Skip the argument
        cpu_advance(cpu)
    }

    cpu_advance(cpu)
}

bne: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    if .Zero not_in cpu.status {
        new_pc := fetch_relative(cpu)

        // Check for page crossing
        if new_pc & 0xff00 != cpu.program_counter {
            cpu.cycle += 1
        }
        cpu.program_counter = new_pc
    } else {
        // Skip the argument
        cpu_advance(cpu)
    }

    cpu_advance(cpu)
}

bit: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    bit_test := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))

    test_result := cpu.accumulator | bit_test

    status_check_zero(cpu, test_result)
    status_check_negative(cpu, bit_test)
    status_check_overflow(cpu, bit_test)

    cpu_advance(cpu)
}

bvs: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    if .Overflow in cpu.status {
        new_pc := fetch_relative(cpu)

        // Check for page crossing
        if new_pc & 0xff00 != cpu.program_counter {
            cpu.cycle += 1
        }
        cpu.program_counter = new_pc
    } else {
        // Skip the argument
        cpu_advance(cpu)
    }

    cpu_advance(cpu)
}

bvc: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    if .Overflow not_in cpu.status {
        new_pc := fetch_relative(cpu)

        // Check for page crossing
        if new_pc & 0xff00 != cpu.program_counter {
            cpu.cycle += 1
        }
        cpu.program_counter = new_pc
    } else {
        // Skip the argument
        cpu_advance(cpu)
    }

    cpu_advance(cpu)
}

bpl: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    if .Negative not_in cpu.status {
        new_pc := fetch_relative(cpu)

        // Check for page crossing
        if new_pc & 0xff00 != cpu.program_counter {
            cpu.cycle += 1
        }
        cpu.program_counter = new_pc
    } else {
        // Skip the argument
        cpu_advance(cpu)
    }

    cpu_advance(cpu)
}

bmi: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    if .Negative in cpu.status {
        new_pc := fetch_relative(cpu)

        // Check for page crossing
        if new_pc & 0xff00 != cpu.program_counter {
            cpu.cycle += 1
        }
        cpu.program_counter = new_pc
    } else {
        // Skip the argument
        cpu_advance(cpu)
    }

    cpu_advance(cpu)
}

sei: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu.disable_interrupt_update = true
    cpu.cycle += 1

    cpu_advance(cpu)
}

sed: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu.status += {.Decimal_Mode}
    cpu.cycle += 1

    cpu_advance(cpu)
}

cld: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu.status -= {.Decimal_Mode}
    cpu.cycle += 1

    cpu_advance(cpu)
}

php: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_status := cpu.status
    cpu_status += {.Break} // Always enabled by this instruction
    cpu.cycle += 1

    stack_push(cpu, transmute(u8)cpu_status)
    cpu.cycle += 1

    cpu_advance(cpu)
}

plp: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    new_status_byte := stack_pop(cpu)
    new_status := transmute(CPU_Status)new_status_byte
    cpu.cycle += 1

    cpu.status = new_status
    cpu.cycle += 1

    cpu.status += {.Always_1}
    cpu.cycle += 1

    cpu_advance(cpu)
}

pha: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    stack_push(cpu, cpu.accumulator)
    cpu.cycle += 2

    cpu_advance(cpu)
}

pla: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_status := stack_pop(cpu)
    cpu.cycle += 1

    cpu.accumulator = cpu_status
    cpu.cycle += 1

    status_check_zero(cpu, cpu_status)
    status_check_negative(cpu, cpu_status)
    cpu.cycle += 1

    cpu_advance(cpu)
}

and: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    test_val := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))

    cpu.accumulator = cpu.accumulator & test_val
    status_check_zero(cpu, cpu.accumulator)
    status_check_negative(cpu, cpu.accumulator)

    cpu_advance(cpu)
}

cmp: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address_val := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))
    test_val := cpu.accumulator - address_val

    status_check_negative(cpu, test_val)

    if cpu.accumulator >= address_val {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    if cpu.accumulator == address_val {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    cpu_advance(cpu)
}
