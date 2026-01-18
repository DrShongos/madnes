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

@(private)
add_with_zero_page :: proc(cpu: ^CPU, address: u16, offset: u16) -> u16 {
    new_addr := address + offset
    if new_addr > 0x00ff {
        new_addr &= 0x00ff
    }

    return new_addr
}

fetch_zero_page :: proc(cpu: ^CPU) -> u16 {
    hi := cpu_fetch(cpu)

    // Consumes an additional cycle
    cpu.cycle += 1

    return bytes_to_address(hi, 0x00)
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
    hi := cpu_fetch(cpu)

    // Consumes additional 2 cycles
    cpu.cycle += 2

    return bytes_to_address(hi + register, 0x00)
}

fetch_absolute_indexed :: proc(cpu: ^CPU, register: u8) -> u16 {
    hi := cpu_fetch(cpu)
    lo := cpu_fetch(cpu)

    address := bytes_to_address(hi, lo)
    new_address := address + u16(register)

    // Check whether the calculation will cause the high byte to change,
    // triggering a page cross.
    if address & 0x00ff < new_address & 0x00ff ||
       address & 0xff00 > new_address & 0xff00 {
        cpu.cycle += 1
    }

    return new_address
}

fetch_indexed_indirect :: proc(cpu: ^CPU) -> u16 {
    hi := cpu_fetch(cpu)
    addr := bytes_to_address(hi, 0x00)
    cpu.cycle += 1

    addr = add_with_zero_page(cpu, addr, u16(cpu.reg_x))

    new_hi := cpu_mem_read(cpu, addr)
    addr = add_with_zero_page(cpu, addr, 1)
    new_lo := cpu_mem_read(cpu, addr)

    cpu.cycle += 2

    new_address := bytes_to_address(new_hi, new_lo)
    cpu.cycle += 1

    return new_address
}

fetch_indirect_indexed :: proc(cpu: ^CPU) -> u16 {
    hi := cpu_fetch(cpu)
    cpu.cycle += 1

    addr := bytes_to_address(hi, 0x00)
    new_hi := cpu_mem_read(cpu, addr)
    addr = add_with_zero_page(cpu, addr, 1)
    new_lo := cpu_mem_read(cpu, addr)

    // Check whether the calculation will cause the high byte to change,
    // triggering a page cross.
    actual_address := bytes_to_address(new_hi, new_lo)
    new_address := actual_address + u16(cpu.reg_y)
    if actual_address & 0x00ff < new_address & 0x00ff ||
       actual_address & 0xff00 > new_address & 0xff00 {
        cpu.cycle += 1
    }

    cpu.cycle += 2

    cpu.cycle += 1

    return new_address
}

fetch_indirect :: proc(cpu: ^CPU) -> u16 {
    hi := cpu_fetch(cpu)
    lo := cpu_fetch(cpu)

    addr := bytes_to_address(hi, lo)
    new_hi := cpu_mem_read(cpu, addr)
    // In the real 6502, there is a bug related to the JMP instruction where
    // Trying to set the program counter to the end of a page (0xXXff)
    // Ends up with the CPU failing to increment the value, causing the PC
    // To jump to the start of the address page (0xXX00)
    if addr & 0x00ff != 0x00ff {
        addr += 1
    } else {
        addr = bytes_to_address(0x00, lo)
    }
    new_lo := cpu_mem_read(cpu, addr)

    cpu.cycle += 2


    new_address := bytes_to_address(new_hi, new_lo)

    return new_address
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
    case .Indexed_Indirect:
        return fetch_indexed_indirect(cpu)
    case .Indirect_Indexed:
        return fetch_indirect_indexed(cpu)
    case .Indirect:
        return fetch_indirect(cpu)
    }

    fmt.println(
        "The current instruction used an impossible addressing mode. Terminating",
    )
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

rti: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu_status := stack_pop(cpu)
    cpu.status = transmute(CPU_Status)cpu_status
    cpu.status += {.Always_1}

    cpu.cycle += 1

    pc_hi := stack_pop(cpu)
    cpu.cycle += 1

    pc_lo := stack_pop(cpu)
    cpu.cycle += 1

    cpu.program_counter = bytes_to_address(pc_hi, pc_lo)
    cpu.cycle += 3
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

    if addressing_mode == .Zero_Page {
        cpu.cycle -= 1
    }
    value := cpu_mem_read(cpu, address)
    cpu_set_accumulator(cpu, value)

    cpu_advance(cpu)
}

store_register :: proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
    register: u8,
) {
    address := fetch_address(cpu, addressing_mode)
    cpu_mem_write(cpu, address, register)
    if addressing_mode == .Absolute {
        cpu.cycle += 1
    }

    cpu_advance(cpu)
}

stx: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    store_register(cpu, addressing_mode, cpu.reg_x)
}

sty: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    store_register(cpu, addressing_mode, cpu.reg_y)
}

sta: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    store_register(cpu, addressing_mode, cpu.accumulator)
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
    set_flag(cpu, {.Carry})
}

clc: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    clear_flag(cpu, {.Carry})
}

branch_if :: proc(cpu: ^CPU, condition: bool) {
    if condition {
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

bcs: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    branch_if(cpu, .Carry in cpu.status)
}

bcc: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    branch_if(cpu, .Carry not_in cpu.status)
}

beq: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    branch_if(cpu, .Zero in cpu.status)
}

bne: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    branch_if(cpu, .Zero not_in cpu.status)
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
    branch_if(cpu, .Overflow in cpu.status)
}

bvc: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    branch_if(cpu, .Overflow not_in cpu.status)
}

bpl: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    branch_if(cpu, .Negative not_in cpu.status)
}

bmi: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    branch_if(cpu, .Negative in cpu.status)
}

sei: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    cpu.disable_interrupt_update = true
    cpu.cycle += 1

    cpu_advance(cpu)
}

set_flag :: proc(cpu: ^CPU, flag: CPU_Status) {
    cpu.status += flag
    cpu.cycle += 1

    cpu_advance(cpu)
}

clear_flag :: proc(cpu: ^CPU, flag: CPU_Status) {
    cpu.status -= flag
    cpu.cycle += 1

    cpu_advance(cpu)
}

sed: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    set_flag(cpu, {.Decimal_Mode})
}

cld: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    clear_flag(cpu, {.Decimal_Mode})
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
    // The break flag is always ignored
    cpu.status -= {.Break}
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

    cpu_set_accumulator(cpu, cpu_status)
    cpu.cycle += 2

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

compare_register :: proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
    register: u8,
) {
    address_val := cpu_mem_read(cpu, fetch_address(cpu, addressing_mode))
    test_val := register - address_val

    status_check_negative(cpu, test_val)

    if register >= address_val {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    if register == address_val {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    cpu_advance(cpu)

}

cmp: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    compare_register(cpu, addressing_mode, cpu.accumulator)
}

cpy: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    compare_register(cpu, addressing_mode, cpu.reg_y)
}

cpx: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    compare_register(cpu, addressing_mode, cpu.reg_x)
}

clv: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    clear_flag(cpu, {.Overflow})
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
    // Invert all the bits in the argument to turn adding into subtracting.
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

lsr: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    val: u8
    addr: u16
    if addressing_mode == .Accumulator {
        val = cpu.accumulator
    } else {
        addr = fetch_address(cpu, addressing_mode)
        val = cpu_mem_read(cpu, addr)
        cpu.cycle += 1
    }

    result := val >> 1

    if val & 0x01 != 0 {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    cpu.status -= {.Negative}
    status_check_zero(cpu, result)
    cpu.cycle += 1

    if addressing_mode == .Accumulator {
        cpu.accumulator = result
    } else {
        cpu_mem_write(cpu, addr, result)
        cpu.cycle += 2
    }

    cpu_advance(cpu)
}

asl: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    val: u8
    addr: u16
    if addressing_mode == .Accumulator {
        val = cpu.accumulator
    } else {
        addr = fetch_address(cpu, addressing_mode)
        val = cpu_mem_read(cpu, addr)
        cpu.cycle += 1
    }

    result := val << 1

    if val & 0x80 != 0 {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    status_check_negative(cpu, result)
    status_check_zero(cpu, result)
    cpu.cycle += 1

    if addressing_mode == .Accumulator {
        cpu.accumulator = result
    } else {
        cpu_mem_write(cpu, addr, result)
        cpu.cycle += 2
    }

    cpu_advance(cpu)
}

ror: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    val: u8
    addr: u16
    if addressing_mode == .Accumulator {
        val = cpu.accumulator
    } else {
        addr = fetch_address(cpu, addressing_mode)
        val = cpu_mem_read(cpu, addr)
        cpu.cycle += 1
    }

    result := ((val >> 1) & 0x7f) | transmute(u8)(cpu.status & {.Carry}) << 7

    if val & 0x01 != 0 {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    status_check_zero(cpu, result)
    status_check_negative(cpu, result)
    cpu.cycle += 1

    if addressing_mode == .Accumulator {
        cpu.accumulator = result
    } else {
        cpu_mem_write(cpu, addr, result)
        cpu.cycle += 2
    }

    cpu_advance(cpu)
}

rol: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    val: u8
    addr: u16
    if addressing_mode == .Accumulator {
        val = cpu.accumulator
    } else {
        addr := fetch_address(cpu, addressing_mode)
        val = cpu_mem_read(cpu, addr)
        cpu.cycle += 1
    }

    result := ((val << 1) & 0xfe) | transmute(u8)(cpu.status & {.Carry})

    if val & 0x80 != 0 {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    status_check_zero(cpu, result)
    status_check_negative(cpu, result)
    cpu.cycle += 1

    if addressing_mode == .Accumulator {
        cpu.accumulator = result
    } else {
        cpu_mem_write(cpu, addr, result)
    }

    cpu_advance(cpu)
}
