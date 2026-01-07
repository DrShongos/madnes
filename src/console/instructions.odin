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

stx: Instruction_Code : proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
) {
    address := fetch_address(cpu, addressing_mode)
    cpu_mem_write(cpu, address, cpu.reg_x)

    cpu_advance(cpu)
}
