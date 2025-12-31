package console

import "core:fmt"

invalid_instruction: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    fmt.eprintf(
        "ERROR: Unknown opcode %x. Possibly unimplemented by the emulator. \n",
        cpu_mem_read(cpu, cpu.program_counter),
    )
    return 255
}

jmp :: proc(cpu: ^CPU, address: u16) {
    // TODO: Implement the page crossing bug.
    cpu.program_counter = address
}

jmp_absolute: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    hi := cpu_fetch(cpu)
    lo := cpu_fetch(cpu)

    address := bytes_to_address(hi, lo)
    jmp(cpu, address)

    return 3
}

ldx :: proc(cpu: ^CPU, value: u8) {
    cpu.reg_x = value

    if value == 0 {
        cpu.status += {.Zero}
    }

    if value & 0b10000000 != 0 {
        cpu.status += {.Negative}
    }

    cpu.program_counter += 1
}

ldx_immediate: Instruction_Code : proc(cpu: ^CPU) -> u8 {
    arg := cpu_fetch(cpu)
    ldx(cpu, arg)

    return 2
}
