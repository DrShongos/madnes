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

status_check_arithmetic_overflow :: proc(
    cpu: ^CPU,
    result_val: u8,
    arg_val: u8,
) {
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

    stack_push(cpu, pc_lo)
    cpu.cycle += 1

    stack_push(cpu, pc_hi)
    cpu.cycle += 1

    cpu.program_counter = address
    cpu.cycle += 2
}

rts: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    pc_hi := stack_pop(cpu)
    cpu.cycle += 1

    pc_lo := stack_pop(cpu)
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
    if addressing_mode == .Absolute {
        cpu.cycle += 1
    }
    value := cpu_mem_read(cpu, address)
    cpu_set_reg_x(cpu, value)

    cpu_advance(cpu)
}

ldy: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    if addressing_mode == .Absolute {
        cpu.cycle += 1
    }
    value := cpu_mem_read(cpu, address)
    cpu_set_reg_y(cpu, value)

    cpu_advance(cpu)
}

lda: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    if addressing_mode == .Absolute {
        cpu.cycle += 1
    }
    value := cpu_mem_read(cpu, address)
    cpu_set_accumulator(cpu, value)

    cpu_advance(cpu)
}

stx: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    cpu_mem_write(cpu, address, cpu.reg_x)
    if addressing_mode == .Absolute {
        cpu.cycle += 1
    }

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

    test_result := cpu.accumulator & bit_test

    status_check_zero(cpu, test_result)
    status_check_negative(cpu, bit_test)
    status_check_overflow(cpu, bit_test)
    cpu.status += {.Always_1}

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

    cpu_set_accumulator(cpu, cpu.accumulator & test_val)

    cpu_advance(cpu)
}

ora: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    test_val := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))

    cpu_set_accumulator(cpu, cpu.accumulator | test_val)

    cpu_advance(cpu)
}

eor: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    test_val := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))

    cpu_set_accumulator(cpu, cpu.accumulator ~ test_val)

    cpu_advance(cpu)
}

cmp: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address_val := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))
    fmt.printf("ADDRESS VAL = %x \n", address_val)
    test_val := cpu.accumulator - address_val

    status_check_negative(cpu, test_val)
    fmt.printf("TEST VAL = %x \n", test_val)

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

cpy: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address_val := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))
    test_val := cpu.reg_y - address_val

    status_check_negative(cpu, test_val)

    if cpu.reg_y >= address_val {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    if cpu.reg_y == address_val {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    cpu_advance(cpu)
}

cpx: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address_val := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))
    test_val := cpu.reg_x - address_val

    status_check_negative(cpu, test_val)

    if cpu.reg_x >= address_val {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    if cpu.reg_x == address_val {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    cpu_advance(cpu)
}

clv: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu.status -= {.Overflow}
    cpu.cycle += 1

    cpu_advance(cpu)
}

adc: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    arg := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))

    carry := transmute(u8)(cpu.status & {.Carry})

    // Checks if the result of an arithmetic instruction would cause the value to wrap around.
    carry_test := u16(cpu.accumulator) + u16(arg) + u16(carry)
    if carry_test > 0xff {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    result := cpu.accumulator + arg + carry
    status_check_zero(cpu, result)
    status_check_negative(cpu, result)

    if ((cpu.accumulator ~ result) & (arg ~ result) & 0x80) == 0x80 {
        cpu.status += {.Overflow}
    } else {
        cpu.status -= {.Overflow}
    }

    // Set the accumulator to the result after everything has been tested
    cpu.accumulator = result

    cpu_advance(cpu)
}

sbc: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    arg := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))
    arg = ~arg

    carry := transmute(u8)(cpu.status & {.Carry})

    // Checks if the result of an arithmetic instruction would cause the value to wrap around.
    carry_test := u16(cpu.accumulator) + u16(arg) + u16(carry)
    if carry_test >> 8 != 0 {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    result := cpu.accumulator + arg + carry
    status_check_zero(cpu, result)
    status_check_negative(cpu, result)

    if ((cpu.accumulator ~ result) & (arg ~ result) & 0x80) == 0x80 {
        cpu.status += {.Overflow}
    } else {
        cpu.status -= {.Overflow}
    }

    // Set the accumulator to the result after everything has been tested
    cpu.accumulator = result

    cpu_advance(cpu)
}

iny: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_set_reg_y(cpu, cpu.reg_y + 1)
    cpu.cycle += 1

    cpu_advance(cpu)
}

inx: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_set_reg_x(cpu, cpu.reg_x + 1)
    cpu.cycle += 1

    cpu_advance(cpu)
}

inc: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    arg := cpu_mem_read(cpu, address)
    arg += 1
    cpu.cycle += 1

    cpu_mem_write(cpu, address, arg)
    cpu.cycle += 1

    status_check_zero(cpu, arg)
    status_check_negative(cpu, arg)

    cpu_advance(cpu)
}

dey: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_set_reg_y(cpu, cpu.reg_y - 1)
    cpu.cycle += 1

    cpu_advance(cpu)
}

dex: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_set_reg_x(cpu, cpu.reg_x - 1)
    cpu.cycle += 1

    cpu_advance(cpu)
}

dec: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    arg := cpu_mem_read(cpu, address)
    arg -= 1
    cpu.cycle += 1

    cpu_mem_write(cpu, address, arg)
    cpu.cycle += 1

    status_check_zero(cpu, arg)
    status_check_negative(cpu, arg)

    cpu_advance(cpu)
}

tax: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_set_reg_x(cpu, cpu.accumulator)
    cpu.cycle += 1

    cpu_advance(cpu)
}

tay: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_set_reg_y(cpu, cpu.accumulator)
    cpu.cycle += 1

    cpu_advance(cpu)
}

tsx: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_set_reg_x(cpu, cpu.stack_top)
    cpu.cycle += 1

    cpu_advance(cpu)
}

txa: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_set_accumulator(cpu, cpu.reg_x)
    cpu.cycle += 1

    cpu_advance(cpu)
}

tya: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_set_accumulator(cpu, cpu.reg_y)
    cpu.cycle += 1

    cpu_advance(cpu)
}

txs: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu.stack_top = cpu.reg_x
    cpu.cycle += 1

    cpu_advance(cpu)
}
