package console

import "core:fmt"
import "core:os"

DEFAULT_STATUS: u8 : 0x24

CPU_MEM_SIZE: u16 : 0xffff

PROGRAM_ROM_START: u16 : 0x8000
PROGRAM_ROM_MIRROR: u16 : 0xc000

STACK_TOP: u8 : 0xfd

CPU_Status_Flags :: enum {
    /// This bit checks whether the result of the last math operation was a negative value.
    Negative          = 7,
    Overflow          = 6,

    /// Unused bit, has no effect on the CPU beyond being always set to 1.
    Always_1          = 5,
    Break             = 4,

    /// The decimal mode is unused by the NES.
    Decimal_Mode      = 3,
    Interrupt_Disable = 2,

    /// The bit checks whether the result of the last math operation was a zero.
    Zero              = 1,
    Carry             = 0,
}

CPU_Status :: bit_set[CPU_Status_Flags]

CPU :: struct {
    status:          CPU_Status,
    accumulator:     u8,
    reg_x:           u8,
    reg_y:           u8,
    stack_top:       u8,
    program_counter: u16,
    memory:          [CPU_MEM_SIZE]u8,

    // Instruction info

    // The amount of cycles used to perform the instruction
    cycle:           u8,
    instruction_set: [INSTRUCTION_SET_SIZE]Instruction,

    // This value specifies whether during accessing an indexed address
    // The calculation caused the high byte to change, forcing it to start fetching again.
    // Used to add an additional cycle during the execution of an instruction,
    // gets reset on the next tick.
    page_crossed:    bool,
}

@(private)
mem_reset :: proc(cpu: ^CPU) {
    // TODO: The actual NES fills the memory with random values at start.
    // This is used by multiple games for RNG.
    // This should be configurable.
    for i := 0; i < auto_cast CPU_MEM_SIZE; i += 1 {
        cpu.memory[i] = 0
    }
}

cpu_new :: proc() -> CPU {
    cpu := CPU {
        status          = transmute(CPU_Status)DEFAULT_STATUS,
        accumulator     = 0,
        reg_x           = 0,
        reg_y           = 0,
        stack_top       = STACK_TOP,
        program_counter = PROGRAM_ROM_MIRROR,
        cycle           = 0,
        instruction_set = instruction_set_create(),
        page_crossed    = false,
    }

    mem_reset(&cpu)

    return cpu
}

/// Converts two bytes in the little endian order into an u16 value.
bytes_to_address :: proc(hi: u8, lo: u8) -> u16 {
    hi := u16(hi)
    lo := u16(lo)
    word: u16 = u16(hi | (lo << 8))

    return word
}

/// Converts an u16 value into a tuple of two bytes.
/// The bytes are returned in the little endian order.
address_to_bytes :: proc(address: u16) -> (u8, u8) {
    hi := (address & 0xff)
    lo := address >> 8

    return u8(hi), u8(lo)
}

cpu_mem_read :: proc(cpu: ^CPU, address: u16) -> u8 {
    if address <= 0x07ff {
        return cpu.memory[address]
    }

    // RAM Mirror 1
    if address >= 0x0800 && address <= 0x0fff {
        return cpu.memory[address - 0x0800]
    }

    // RAM Mirror 2
    if address >= 0x1000 && address <= 0x17ff {
        return cpu.memory[address - 0x1000]
    }

    // RAM Mirror 3
    if address >= 0x1800 && address <= 0x1fff {
        return cpu.memory[address - 0x1800]
    }

    // TODO: Read memory from the other parts of the console (BUS)
    return cpu.memory[address]
}

cpu_mem_write :: proc(cpu: ^CPU, address: u16, value: u8) {
    if address <= 0x07ff {
        cpu.memory[address] = value
    }

    // RAM Mirror 1
    if address >= 0x0800 && address <= 0x0fff {
        cpu.memory[address - 0x0800] = value
    }

    // RAM Mirror 2
    if address >= 0x1000 && address <= 0x17ff {
        cpu.memory[address - 0x1000] = value
    }

    // RAM Mirror 3
    if address >= 0x1800 && address <= 0x1fff {
        cpu.memory[address - 0x1800] = value
    }

    // TODO: Write to the other parts of the console
    cpu.memory[address] = value
}

cpu_fetch :: proc(cpu: ^CPU) -> u8 {
    cpu.program_counter += 1

    return cpu_mem_read(cpu, cpu.program_counter)
}

cpu_instruction_trace :: proc(cpu: ^CPU, instruction: ^Instruction) {
    // Address, Opcode
    fmt.printf(
        "%x %x ",
        cpu.program_counter,
        cpu_mem_read(cpu, cpu.program_counter),
    )

    // TODO: Addressing Mode
    //
    // Opcode name
    fmt.printf(" %s ", instruction.name)

    // CPU values pre-execution
    fmt.printf(
        "            A:%x X:%x Y:%x P:%x, SP:%x\n",
        cpu.accumulator,
        cpu.reg_x,
        cpu.reg_y,
        transmute(u8)cpu.status,
        cpu.stack_top,
    )
}

cpu_tick :: proc(cpu: ^CPU) {
    cpu.page_crossed = false
    opcode := cpu_mem_read(cpu, cpu.program_counter)
    instruction := cpu.instruction_set[opcode]

    cpu_instruction_trace(cpu, &instruction)
    cpu.cycle = instruction.action(cpu)

    // Page crossing forces the CPU to re-calculate the instruction's argument,
    // Spending an additional cycle on doing so.
    if cpu.page_crossed {
        cpu.cycle += 1
    }

    // Force the emulator to shutdown if an unsupported opcode gets executed.
    if cpu.cycle == 255 {
        os.exit(-1)
    }
}

stack_push :: proc(cpu: ^CPU, value: u8) {
    cpu.memory[cpu.stack_top] = value
    cpu.stack_top -= 1
}

stack_pop :: proc(cpu: ^CPU) -> u8 {
    cpu.stack_top += 1
    return cpu.memory[cpu.stack_top]
}
