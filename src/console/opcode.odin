package console

import "core:fmt"
import "core:os"

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
    Indirect_Indexed,
}

Opcode :: struct {
    name:            string,
    addressing_mode: Addressing_Mode,
    action:          proc(
        cpu: ^CPU,
        console: ^Console,
        addressing_mode: Addressing_Mode,
    ) -> u8,
}

trace_opcode :: proc(opcode: ^Opcode, cpu: ^CPU, console: ^Console) {
    fmt.printf(
        "%x %x ",
        cpu.program_counter,
        read_memory(cpu, console, cpu.program_counter),
    )

    #partial switch opcode.addressing_mode {
    case .Implied:
        fmt.printf("      ")
    case .Immediate, .Zero_Page, .Zero_Page_Y, .Zero_Page_X, .Indexed_Indirect, .Indirect_Indexed, .Relative:
        fmt.printf("%x    ", cpu.memory[cpu.program_counter + 1])
    case .Absolute, .Absolute_X, .Absolute_Y, .Indirect:
        fmt.printf(
            "%x %x ",
            read_memory(cpu, console, cpu.program_counter + 1),
            read_memory(cpu, console, cpu.program_counter + 2),
        )
    }

    fmt.printf("  ")

    fmt.printf("%s ", opcode.name)
    #partial switch opcode.addressing_mode {
    case .Absolute:
        fmt.printf(
            "$%x   ",
            u8_to_u16(
                read_memory(cpu, console, cpu.program_counter + 1),
                read_memory(cpu, console, cpu.program_counter + 2),
            ),
        )
    case .Absolute_X:
        fmt.printf(
            "$%x,X ",
            u8_to_u16(
                read_memory(cpu, console, cpu.program_counter + 1),
                read_memory(cpu, console, cpu.program_counter + 2),
            ),
        )
    case .Absolute_Y:
        fmt.printf(
            "$%x,Y ",
            u8_to_u16(
                read_memory(cpu, console, cpu.program_counter + 1),
                read_memory(cpu, console, cpu.program_counter + 2),
            ),
        )
    case .Indirect:
        fmt.printf(
            "(%x) ",
            u8_to_u16(
                read_memory(cpu, console, cpu.program_counter + 1),
                read_memory(cpu, console, cpu.program_counter + 2),
            ),
        )
    case .Accumulator:
        fmt.printf("A ")
    case .Immediate:
        fmt.printf("#%x ", read_memory(cpu, console, cpu.program_counter + 1))
    case .Zero_Page:
        fmt.printf("$%x ", read_memory(cpu, console, cpu.program_counter + 1))
    case .Zero_Page_X:
        fmt.printf(
            "$%x,X ",
            read_memory(cpu, console, cpu.program_counter + 1),
        )
    case .Zero_Page_Y:
        fmt.printf(
            "$%x,Y ",
            read_memory(cpu, console, cpu.program_counter + 1),
        )
    case .Indexed_Indirect:
        fmt.printf(
            "($%x,X) ",
            read_memory(cpu, console, cpu.program_counter + 1),
        )
    case .Indirect_Indexed:
        fmt.printf(
            "($%x),Y ",
            read_memory(cpu, console, cpu.program_counter + 1),
        )
    case .Relative:
        fmt.printf(
            "*.%d ",
            i8(read_memory(cpu, console, cpu.program_counter + 1)),
        )
    case .Implied:
        fmt.printf("     ")
    }

    fmt.printf(
        "            A:%x X:%x Y:%x P:%x, SP:%x, CYCLES: %d\n",
        cpu.accumulator,
        cpu.register_x,
        cpu.register_y,
        transmute(u8)cpu.status,
        cpu.stack_top,
        cpu.executed_cycles,
    )
}

is_negative :: proc(number: u8) -> bool {
    return number & 0b10000000 != 0
}

execute_opcode :: proc(opcode: ^Opcode, cpu: ^CPU, console: ^Console) -> u8 {
    trace_opcode(opcode, cpu, console)
    return opcode.action(cpu, console, opcode.addressing_mode)
}

zero_page_wrap :: proc(mem: u16, add: u16, cpu: ^CPU) -> u16 {
    new_address := mem + add

    if new_address > 0xFF {
        cpu.page_crossed = true
        return new_address - 0xFF
    }

    return new_address
}

read_address :: proc(
    mode: Addressing_Mode,
    cpu: ^CPU,
    console: ^Console,
) -> (
    u8,
    u8,
) {
    #partial switch mode {
    case .Immediate:
        return cpu_fetch(cpu, console), 0
    case .Zero_Page:
        return cpu_fetch(cpu, console), 0
    case .Zero_Page_X:
        return cpu_fetch(cpu, console) + cpu.register_x, 0
    case .Zero_Page_Y:
        return cpu_fetch(cpu, console) + cpu.register_y, 0
    case .Relative:
        offset := u16(cpu_fetch(cpu, console))
        offset_pc := cpu.program_counter

        if offset & 0x80 != 0 {
            offset |= 0xFF00
        }
        offset_pc += offset

        return u16_to_u8(offset_pc)
    case .Absolute:
        return cpu_fetch(cpu, console), cpu_fetch(cpu, console)
    case .Absolute_X:
        address := u8_to_u16(cpu_fetch(cpu, console), cpu_fetch(cpu, console))
        new_address := address + u16(cpu.register_x)
        if address & 0xFF00 < new_address & 0xFF00 ||
           address & 0xFF00 > new_address & 0xFF00 {
            cpu.page_crossed = true
        }
        return u16_to_u8(address)
    case .Absolute_Y:
        address := u8_to_u16(cpu_fetch(cpu, console), cpu_fetch(cpu, console))
        new_address := address + u16(cpu.register_y)
        if address & 0xFF00 < new_address & 0xFF00 ||
           address & 0xFF00 > new_address & 0xFF00 {
            cpu.page_crossed = true
        }
        return u16_to_u8(address)
    case .Indirect:
        target_hi := cpu_fetch(cpu, console)
        target_lo := cpu_fetch(cpu, console)

        hi_address := u8_to_u16(target_hi, target_lo)

        real_hi := read_memory(cpu, console, hi_address)
        real_lo := read_memory(cpu, console, hi_address + 1)

        // Handle a hardware bug where attempting to fetch the indirect address from the end of a page causes the memory to wrap around
        if hi_address & 0x00FF == 0x00FF {
            // According to the results from the nestest rom these two have to be swapped around in this edge case despite every documentation i've seen not specyfying that.
            // That, or I simply have zero reading comprehension
            // I have literally zero idea if it will work on any other program and I don't want to know
            real_lo = read_memory(cpu, console, u8_to_u16(0x00, target_lo))
            real_hi = read_memory(cpu, console, hi_address)
        }


        return real_hi, real_lo
    case .Indexed_Indirect:
        address := u8_to_u16(cpu_fetch(cpu, console), 0x00)
        new_address := zero_page_wrap(address, u16(cpu.register_x), cpu)

        return u16_to_u8(new_address)
    case .Indirect_Indexed:
        address := u8_to_u16(cpu_fetch(cpu, console), 0x00)
        new_address := zero_page_wrap(address, u16(cpu.register_y), cpu)

        return u16_to_u8(new_address)
    }

    return 0, 0
}

// Returns the byte placed in memory.
// It handles address mirroring and accessing registers of
// Other components of the console.
read_memory :: proc(cpu: ^CPU, console: ^Console, addr: u16) -> u8 {
    if addr >= 0x0000 && addr <= 0x07FF {
        return cpu.memory[addr]
    }
    // Interal RAM Mirrors
    if addr >= 0x0800 && addr <= 0x0FFF {
        return cpu.memory[addr - 0x0800]
    }

    if addr >= 0x1000 && addr <= 0x17FF {
        return cpu.memory[addr - 0x1000]
    }

    if addr >= 0x1800 && addr <= 0x1FFF {
        return cpu.memory[addr - 0x1800]
    }

    // PPU Registers
    if addr >= 0x2000 && addr <= 0x2007 {
        return ppu_read_registers(&console.ppu, addr)
    }

    // PPU Mirrors
    if addr >= 0x2008 && addr <= 0x3fff {
        return ppu_read_registers(&console.ppu, 0x2000 + (addr % 8))
    }

    // TODO: Mapper Registers
    // TODO: IO Registers
    // TODO: APU Registers

    return mapper_read_memory(&console.mapper, addr)
}

// Writes to the byte placed in memory.
// It handles address mirroring and accessing registers of
// Other components of the console.
write_memory :: proc(cpu: ^CPU, console: ^Console, addr: u16, val: u8) {
    // Interal RAM Mirrors
    if addr >= 0x0800 && addr <= 0x0FFF {
        cpu.memory[addr - 0x0800] = val
        return
    }

    if addr >= 0x1000 && addr <= 0x17FF {
        cpu.memory[addr - 0x1000] = val
        return
    }

    if addr >= 0x1800 && addr <= 0x1FFF {
        cpu.memory[addr - 0x1800] = val
        return
    }

    // PPU Registers
    if addr >= 0x2000 && addr <= 0x2007 {
        ppu_write_registers(&console.ppu, console, addr, val)
        return
    }

    // PPU Mirrors
    if addr >= 0x2008 && addr <= 0x3fff {
        ppu_write_registers(&console.ppu, console, 0x2000 + (addr % 8), val)
        return
    }
    // TODO: Mapper Registers
    // TODO: IO Registers
    // TODO: APU Registers

    mapper_write_memory(&console.mapper, addr, val)
}

@(private)
set_register_x :: proc(cpu: ^CPU, value: u8) {
    cpu.register_x = value

    if value == 0 {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    if value & 0b10000000 != 0 {
        cpu.status += {.Negative}
    } else {
        cpu.status -= {.Negative}
    }
}

@(private)
set_register_y :: proc(cpu: ^CPU, value: u8) {
    cpu.register_y = value

    if value == 0 {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    if value & 0b10000000 != 0 {
        cpu.status += {.Negative}
    } else {
        cpu.status -= {.Negative}
    }
}

@(private)
set_accumulator :: proc(cpu: ^CPU, value: u8) {
    cpu.accumulator = value

    if value == 0 {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    if value & 0b10000000 != 0 {
        cpu.status += {.Negative}
    } else {
        cpu.status -= {.Negative}
    }
}

// Writes to the memory and toggles appropriate processor flags
@(private)
set_memory :: proc(cpu: ^CPU, console: ^Console, value: u8, address: u16) {
    write_memory(cpu, console, address, value)

    if value == 0 {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    if value & 0b10000000 != 0 {
        cpu.status += {.Negative}
    } else {
        cpu.status -= {.Negative}
    }
}

invalid :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    fmt.printf(
        "ERROR: Attempted to execute invalid opcode %x\n",
        read_memory(cpu, console, cpu.program_counter),
    )
    return 255
}

brk :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    trigger_interrupt(console, Interrupt.IRQ)
    return 7
}

lda :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    hi, lo := read_address(addressing_mode, cpu, console)

    new_a := hi
    if addressing_mode != .Immediate {
        new_a = read_memory(cpu, console, u8_to_u16(hi, lo))
    }

    set_accumulator(cpu, new_a)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    case .Absolute_X:
        return 4
    case .Absolute_Y:
        return 4
    case .Indexed_Indirect:
        return 6
    case .Indirect_Indexed:
        return 5
    }

    return 4
}

ldx :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    hi, lo := read_address(addressing_mode, cpu, console)

    new_x := hi
    if addressing_mode != .Immediate {
        new_x = read_memory(cpu, console, u8_to_u16(hi, lo))
    }

    set_register_x(cpu, new_x)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Zero_Page_Y:
        return 4
    case .Absolute:
        return 4
    case .Absolute_Y:
        return 4
    }

    return 4
}

ldy :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    hi, lo := read_address(addressing_mode, cpu, console)

    new_y := hi
    if addressing_mode != .Immediate {
        new_y = read_memory(cpu, console, u8_to_u16(hi, lo))
    }

    set_register_y(cpu, new_y)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    case .Absolute_X:
        return 4
    }

    return 4
}

stx :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    addr_hi, addr_lo := read_address(addressing_mode, cpu, console)
    address: u16 = u8_to_u16(addr_hi, addr_lo)

    write_memory(cpu, console, address, cpu.register_x)
    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Zero_Page:
        return 3
    case .Zero_Page_Y:
        return 4
    case .Absolute:
        return 4
    }

    return 4
}

sty :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    addr_hi, addr_lo := read_address(addressing_mode, cpu, console)
    address: u16 = u8_to_u16(addr_hi, addr_lo)

    write_memory(cpu, console, address, cpu.register_y)
    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    }

    return 4
}

sta :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    addr_hi, addr_lo := read_address(addressing_mode, cpu, console)
    address: u16 = u8_to_u16(addr_hi, addr_lo)

    write_memory(cpu, console, address, cpu.accumulator)
    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    case .Absolute_X:
        return 5
    case .Absolute_Y:
        return 5
    case .Indexed_Indirect:
        return 6
    case .Indirect_Indexed:
        return 6
    }

    return 4
}

jmp :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    jump_hi, jump_lo := read_address(addressing_mode, cpu, console)
    cpu.program_counter = u8_to_u16(jump_hi, jump_lo)

    #partial switch addressing_mode {
    case .Absolute:
        return 3
    }

    return 5
}

jsr :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    addr_hi, addr_lo := read_address(addressing_mode, cpu, console)
    address := u8_to_u16(addr_hi, addr_lo)

    // The return point of the subroutine will be the address of the LSB, 
    // which the program counter is pointing towards now
    pc_hi, pc_lo := u16_to_u8(cpu.program_counter)

    stack_push(cpu, pc_lo)
    stack_push(cpu, pc_hi)

    cpu.program_counter = address

    return 6
}

rts :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    hi := stack_pop(cpu)
    lo := stack_pop(cpu)

    return_address := u8_to_u16(hi, lo)
    cpu.program_counter = return_address
    cpu_fetch(cpu, console)

    return 6
}

rti :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    new_status := stack_pop(cpu)
    hi := stack_pop(cpu)
    lo := stack_pop(cpu)

    return_address := u8_to_u16(hi, lo)
    cpu.program_counter = return_address

    cpu.status = transmute(Processor_Status)new_status
    cpu.status += {.Always_1}

    return 6
}

bit :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    hi, lo := read_address(addressing_mode, cpu, console)
    addr := u8_to_u16(hi, lo)

    test_val := read_memory(cpu, console, addr)

    result := test_val & cpu.accumulator
    if result == 0 {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    bit_6 := test_val & 0b01000000
    bit_7 := test_val & 0b10000000

    // There's no way to manually set specific bit_set flag
    if bit_6 == 0 {
        cpu.status -= {.Overflow}
    } else {
        cpu.status += {.Overflow}
    }

    if bit_7 == 0 {
        cpu.status -= {.Negative}
    } else {
        cpu.status += {.Negative}
    }

    cpu_fetch(cpu, console)

    if addressing_mode == .Zero_Page {
        return 3
    }
    return 4
}

and :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    test_val: u8 = 0

    hi, lo := read_address(addressing_mode, cpu, console)
    addr := u8_to_u16(hi, lo)

    test_val = read_memory(cpu, console, addr)
    if addressing_mode == .Immediate {
        test_val = hi
    }

    set_accumulator(cpu, cpu.accumulator & test_val)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    case .Absolute_X:
        return 4
    case .Absolute_Y:
        return 4
    case .Indexed_Indirect:
        return 6
    case .Indirect_Indexed:
        return 5
    }

    return 5 //unreachable
}

adc :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    add_val: u8 = 0

    hi, lo := read_address(addressing_mode, cpu, console)
    addr := u8_to_u16(hi, lo)

    add_val = read_memory(cpu, console, addr)
    if addressing_mode == .Immediate {
        add_val = hi
    }

    result := cpu.accumulator + add_val + transmute(u8)(cpu.status & {.Carry})

    // carry_test is created to check if getting rid of the first 8 bits would leave a potential carry bit behind
    carry_test :=
        u16(cpu.accumulator) +
        u16(add_val) +
        u16(transmute(u8)(cpu.status & {.Carry}))

    // Checks whether the signs of the allocator and the value of the memory would make it impossible to create the result's sign
    if ((cpu.accumulator ~ result) & (add_val ~ result) & 0x80) == 0x80 {
        cpu.status += {.Overflow}
    } else {
        cpu.status -= {.Overflow}
    }

    if carry_test >> 8 != 0 {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    set_accumulator(cpu, result)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    case .Absolute_X:
        return 4
    case .Absolute_Y:
        return 4
    case .Indexed_Indirect:
        return 6
    case .Indirect_Indexed:
        return 5
    }

    return 5 //unreachable
}

sbc :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    add_val: u8 = 0

    hi, lo := read_address(addressing_mode, cpu, console)
    addr := u8_to_u16(hi, lo)

    add_val = read_memory(cpu, console, addr)
    if addressing_mode == .Immediate {
        add_val = hi
    }

    result := cpu.accumulator + ~add_val + transmute(u8)(cpu.status & {.Carry})

    // carry_test is created to check if getting rid of the first 8 bits would leave a potential carry bit behind
    carry_test :=
        u16(cpu.accumulator) +
        u16(~add_val) +
        u16(transmute(u8)(cpu.status & {.Carry}))

    // Checks whether the signs of the allocator and the value of the memory would make it impossible to create the result's sign
    if ((cpu.accumulator ~ result) & (~add_val ~ result) & 0x80) == 0x80 {
        cpu.status += {.Overflow}
    } else {
        cpu.status -= {.Overflow}
    }

    if carry_test >> 8 != 0 {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    set_accumulator(cpu, result)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    case .Absolute_X:
        return 4
    case .Absolute_Y:
        return 4
    case .Indexed_Indirect:
        return 6
    case .Indirect_Indexed:
        return 5
    }

    return 5 //unreachable
}

ora :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    test_val: u8 = 0

    hi, lo := read_address(addressing_mode, cpu, console)
    addr := u8_to_u16(hi, lo)

    test_val = read_memory(cpu, console, addr)
    if addressing_mode == .Immediate {
        test_val = hi
    }

    set_accumulator(cpu, cpu.accumulator | test_val)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    case .Absolute_X:
        return 4
    case .Absolute_Y:
        return 4
    case .Indexed_Indirect:
        return 6
    case .Indirect_Indexed:
        return 5
    }

    return 5 //unreachable
}

eor :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    test_val: u8 = 0

    hi, lo := read_address(addressing_mode, cpu, console)
    addr := u8_to_u16(hi, lo)

    test_val = read_memory(cpu, console, addr)
    if addressing_mode == .Immediate {
        test_val = hi
    }

    set_accumulator(cpu, cpu.accumulator ~ test_val)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    case .Absolute_X:
        return 4
    case .Absolute_Y:
        return 4
    case .Indexed_Indirect:
        return 6
    case .Indirect_Indexed:
        return 5
    }

    return 5 //unreachable
}

bcs :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    offset_hi, offset_lo := read_address(addressing_mode, cpu, console)
    pc_move := u8_to_u16(offset_hi, offset_lo)

    if .Carry in cpu.status {
        prev_pc := cpu.program_counter
        cpu.program_counter = pc_move
        cpu_fetch(cpu, console)

        if (pc_move & 0xFF00) > (prev_pc & 0xFF00) ||
           (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
            return 5
        }
        return 3
    }

    cpu_fetch(cpu, console)
    return 2
}

bvs :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    offset_hi, offset_lo := read_address(addressing_mode, cpu, console)
    pc_move := u8_to_u16(offset_hi, offset_lo)

    if .Overflow in cpu.status {
        prev_pc := cpu.program_counter
        cpu.program_counter = pc_move
        cpu_fetch(cpu, console)

        if (pc_move & 0xFF00) > (prev_pc & 0xFF00) ||
           (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
            return 5
        }
        return 3
    }

    cpu_fetch(cpu, console)
    return 2
}

bvc :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    offset_hi, offset_lo := read_address(addressing_mode, cpu, console)
    pc_move := u8_to_u16(offset_hi, offset_lo)

    if !(.Overflow in cpu.status) {
        prev_pc := cpu.program_counter
        cpu.program_counter = pc_move
        cpu_fetch(cpu, console)

        if (pc_move & 0xFF00) > (prev_pc & 0xFF00) ||
           (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
            return 5
        }
        return 3
    }

    cpu_fetch(cpu, console)
    return 2
}

bcc :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    offset_hi, offset_lo := read_address(addressing_mode, cpu, console)
    pc_move := u8_to_u16(offset_hi, offset_lo)

    if !(.Carry in cpu.status) {
        prev_pc := cpu.program_counter
        cpu.program_counter = pc_move
        cpu_fetch(cpu, console)

        if (pc_move & 0xFF00) > (prev_pc & 0xFF00) ||
           (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
            return 5
        }
        return 3
    }

    cpu_fetch(cpu, console)
    return 2
}

beq :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    offset_hi, offset_lo := read_address(addressing_mode, cpu, console)
    pc_move := u8_to_u16(offset_hi, offset_lo)

    if .Zero in cpu.status {
        prev_pc := cpu.program_counter
        cpu.program_counter = pc_move
        cpu_fetch(cpu, console)

        if (pc_move & 0xFF00) > (prev_pc & 0xFF00) ||
           (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
            return 5
        }
        return 3
    }

    cpu_fetch(cpu, console)
    return 2
}

bne :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    offset_hi, offset_lo := read_address(addressing_mode, cpu, console)
    pc_move := u8_to_u16(offset_hi, offset_lo)

    if !(.Zero in cpu.status) {
        prev_pc := cpu.program_counter
        cpu.program_counter = pc_move
        cpu_fetch(cpu, console)

        if (pc_move & 0xFF00) > (prev_pc & 0xFF00) ||
           (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
            return 5
        }
        return 3
    }

    cpu_fetch(cpu, console)
    return 2
}

bmi :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    offset_hi, offset_lo := read_address(addressing_mode, cpu, console)
    pc_move := u8_to_u16(offset_hi, offset_lo)

    if .Negative in cpu.status {
        prev_pc := cpu.program_counter
        cpu.program_counter = pc_move
        cpu_fetch(cpu, console)

        if (pc_move & 0xFF00) > (prev_pc & 0xFF00) ||
           (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
            return 5
        }
        return 3
    }

    cpu_fetch(cpu, console)
    return 2
}

bpl :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    offset_hi, offset_lo := read_address(addressing_mode, cpu, console)
    pc_move := u8_to_u16(offset_hi, offset_lo)

    if !(.Negative in cpu.status) {
        prev_pc := cpu.program_counter
        cpu.program_counter = pc_move
        cpu_fetch(cpu, console)

        if (pc_move & 0xFF00) > (prev_pc & 0xFF00) ||
           (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
            return 5
        }
        return 3
    }

    cpu_fetch(cpu, console)
    return 2
}

sec :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    cpu.status += {.Carry}
    cpu_fetch(cpu, console)
    return 2
}

sei :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    cpu.status += {.Interrupt_Disable}
    cpu_fetch(cpu, console)
    return 2
}

sed :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    cpu.status += {.Decimal_Mode}
    cpu_fetch(cpu, console)
    return 2
}

clc :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    cpu.status -= {.Carry}
    cpu_fetch(cpu, console)
    return 2
}

nop :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    cpu_fetch(cpu, console)
    return 2
}

php :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    stack_push(cpu, transmute(u8)cpu.status)
    cpu_fetch(cpu, console)
    return 3
}

cmp :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    read_hi, read_lo := read_address(addressing_mode, cpu, console)

    test_val := read_memory(cpu, console, u8_to_u16(read_hi, read_lo))
    if addressing_mode == Addressing_Mode.Immediate {
        test_val = read_hi
    }

    if cpu.accumulator >= test_val {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    if cpu.accumulator == test_val {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    test_result := cpu.accumulator - test_val

    if test_result & 0b10000000 != 0 {
        cpu.status += {.Negative}
    } else {
        cpu.status -= {.Negative}
    }

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Zero_Page_X:
        return 4
    case .Absolute:
        return 4
    case .Absolute_X:
        return 4
    case .Absolute_Y:
        return 4
    case .Indexed_Indirect:
        return 6
    case .Indirect_Indexed:
        return 5
    }

    return 1
}

cpy :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    read_hi, read_lo := read_address(addressing_mode, cpu, console)

    test_val := read_memory(cpu, console, u8_to_u16(read_hi, read_lo))
    if addressing_mode == Addressing_Mode.Immediate {
        test_val = read_hi
    }

    if cpu.register_y >= test_val {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    if cpu.register_y == test_val {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    test_result := cpu.register_y - test_val

    if test_result & 0b10000000 != 0 {
        cpu.status += {.Negative}
    } else {
        cpu.status -= {.Negative}
    }

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Absolute:
        return 4
    }

    return 1
}

cpx :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    read_hi, read_lo := read_address(addressing_mode, cpu, console)

    test_val := read_memory(cpu, console, u8_to_u16(read_hi, read_lo))
    if addressing_mode == Addressing_Mode.Immediate {
        test_val = read_hi
    }

    if cpu.register_x >= test_val {
        cpu.status += {.Carry}
    } else {
        cpu.status -= {.Carry}
    }

    if cpu.register_x == test_val {
        cpu.status += {.Zero}
    } else {
        cpu.status -= {.Zero}
    }

    test_result := cpu.register_x - test_val

    if test_result & 0b10000000 != 0 {
        cpu.status += {.Negative}
    } else {
        cpu.status -= {.Negative}
    }

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Immediate:
        return 2
    case .Zero_Page:
        return 3
    case .Absolute:
        return 4
    }

    return 1
}

cld :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    cpu.status -= {.Decimal_Mode}
    cpu_fetch(cpu, console)
    return 2
}

clv :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    cpu.status -= {.Overflow}
    cpu_fetch(cpu, console)
    return 2
}

pla :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_accumulator(cpu, stack_pop(cpu))

    cpu_fetch(cpu, console)

    return 4
}

plp :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    new_status := stack_pop(cpu)
    cpu.status = transmute(Processor_Status)new_status

    // Corrects the 'Always 1' status flag
    cpu.status += {.Always_1}

    cpu_fetch(cpu, console)

    return 4
}

pha :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    stack_push(cpu, cpu.accumulator)

    cpu_fetch(cpu, console)

    return 3
}

dex :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_register_x(cpu, cpu.register_x - 1)

    cpu_fetch(cpu, console)
    return 2
}

inx :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_register_x(cpu, cpu.register_x + 1)

    cpu_fetch(cpu, console)
    return 2
}

dey :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_register_y(cpu, cpu.register_y - 1)

    cpu_fetch(cpu, console)
    return 2
}

dec :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    hi, lo := read_address(addressing_mode, cpu, console)

    addr := u8_to_u16(hi, lo)
    set_memory(cpu, console, read_memory(cpu, console, addr) - 1, addr)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Zero_Page:
        return 5
    case .Zero_Page_X:
        return 6
    case .Absolute:
        return 6
    case .Absolute_X:
        return 7
    }
    return 2
}

iny :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_register_y(cpu, cpu.register_y + 1)

    cpu_fetch(cpu, console)
    return 2
}

inc :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    hi, lo := read_address(addressing_mode, cpu, console)

    addr := u8_to_u16(hi, lo)
    set_memory(cpu, console, read_memory(cpu, console, addr) + 1, addr)

    cpu_fetch(cpu, console)

    #partial switch addressing_mode {
    case .Zero_Page:
        return 5
    case .Zero_Page_X:
        return 6
    case .Absolute:
        return 6
    case .Absolute_X:
        return 7
    }
    return 2
}

tax :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_register_x(cpu, cpu.accumulator)

    cpu_fetch(cpu, console)
    return 2
}

tay :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_register_y(cpu, cpu.accumulator)

    cpu_fetch(cpu, console)
    return 2
}

tya :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_accumulator(cpu, cpu.register_y)

    cpu_fetch(cpu, console)
    return 2
}

txa :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_accumulator(cpu, cpu.register_x)

    cpu_fetch(cpu, console)
    return 2
}

tsx :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    set_register_x(cpu, cpu.stack_top)

    cpu_fetch(cpu, console)
    return 2
}

txs :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    cpu.stack_top = cpu.register_x

    cpu_fetch(cpu, console)
    return 2
}


lsr :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    if addressing_mode == .Accumulator {
        old := cpu.accumulator

        set_accumulator(cpu, cpu.accumulator >> 1)

        if old & 0x01 != 0 {
            cpu.status += {.Carry}
        } else {
            cpu.status -= {.Carry}
        }
    } else {
        hi, lo := read_address(addressing_mode, cpu, console)

        addr := u8_to_u16(hi, lo)
        memory := read_memory(cpu, console, addr)

        result := memory >> 1

        if result == 0 {
            cpu.status += {.Zero}
        } else {
            cpu.status -= {.Zero}
        }

        if is_negative(result) {
            cpu.status += {.Negative}
        } else {
            cpu.status -= {.Negative}
        }

        if memory & 0x01 != 0 {
            cpu.status += {.Carry}
        } else {
            cpu.status -= {.Carry}
        }

        write_memory(cpu, console, addr, result)
    }

    cpu_fetch(cpu, console)
    #partial switch addressing_mode {
    case .Accumulator:
        return 2
    case .Zero_Page:
        return 5
    case .Zero_Page_X:
        return 6
    case .Absolute:
        return 6
    case .Absolute_X:
        return 7
    }

    return 2
}

asl :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    if addressing_mode == .Accumulator {
        old := cpu.accumulator

        set_accumulator(cpu, cpu.accumulator << 1)

        if old & 0x80 != 0 {
            cpu.status += {.Carry}
        } else {
            cpu.status -= {.Carry}
        }
    } else {
        hi, lo := read_address(addressing_mode, cpu, console)

        addr := u8_to_u16(hi, lo)
        memory := read_memory(cpu, console, addr)

        result := memory << 1

        if result == 0 {
            cpu.status += {.Zero}
        } else {
            cpu.status -= {.Zero}
        }

        if is_negative(result) {
            cpu.status += {.Negative}
        } else {
            cpu.status -= {.Negative}
        }

        if memory & 0x80 != 0 {
            cpu.status += {.Carry}
        } else {
            cpu.status -= {.Carry}
        }

        write_memory(cpu, console, addr, result)
    }

    cpu_fetch(cpu, console)
    #partial switch addressing_mode {
    case .Accumulator:
        return 2
    case .Zero_Page:
        return 5
    case .Zero_Page_X:
        return 6
    case .Absolute:
        return 6
    case .Absolute_X:
        return 7
    }

    return 2
}

ror :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    if addressing_mode == .Accumulator {
        old := cpu.accumulator

        new_acc :=
            ((cpu.accumulator >> 1) & 0b01111111) |
            transmute(u8)(cpu.status & {.Carry}) << 7
        set_accumulator(cpu, new_acc)

        if old & 0x01 != 0 {
            cpu.status += {.Carry}
        } else {
            cpu.status -= {.Carry}
        }
    } else {
        hi, lo := read_address(addressing_mode, cpu, console)

        addr := u8_to_u16(hi, lo)
        memory := read_memory(cpu, console, addr)

        result :=
            ((memory >> 1) & 0b01111111) |
            transmute(u8)(cpu.status & {.Carry}) << 7

        if result == 0 {
            cpu.status += {.Zero}
        } else {
            cpu.status -= {.Zero}
        }

        if is_negative(result) {
            cpu.status += {.Negative}
        } else {
            cpu.status -= {.Negative}
        }

        if memory & 0x01 != 0 {
            cpu.status += {.Carry}
        } else {
            cpu.status -= {.Carry}
        }

        write_memory(cpu, console, addr, result)
    }

    cpu_fetch(cpu, console)
    #partial switch addressing_mode {
    case .Accumulator:
        return 2
    case .Zero_Page:
        return 5
    case .Zero_Page_X:
        return 6
    case .Absolute:
        return 6
    case .Absolute_X:
        return 7
    }

    return 2
}

rol :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    if addressing_mode == .Accumulator {
        old := cpu.accumulator

        new_acc :=
            ((cpu.accumulator << 1) & 0b11111110) |
            transmute(u8)(cpu.status & {.Carry})
        set_accumulator(cpu, new_acc)

        if old & 0x80 != 0 {
            cpu.status += {.Carry}
        } else {
            cpu.status -= {.Carry}
        }
    } else {
        hi, lo := read_address(addressing_mode, cpu, console)

        addr := u8_to_u16(hi, lo)
        memory := read_memory(cpu, console, addr)

        result :=
            ((memory << 1) & 0b11111110) | transmute(u8)(cpu.status & {.Carry})

        if result == 0 {
            cpu.status += {.Zero}
        } else {
            cpu.status -= {.Zero}
        }

        if is_negative(result) {
            cpu.status += {.Negative}
        } else {
            cpu.status -= {.Negative}
        }

        if memory & 0x80 != 0 {
            cpu.status += {.Carry}
        } else {
            cpu.status -= {.Carry}
        }

        write_memory(cpu, console, addr, result)
    }

    cpu_fetch(cpu, console)
    #partial switch addressing_mode {
    case .Accumulator:
        return 2
    case .Zero_Page:
        return 5
    case .Zero_Page_X:
        return 6
    case .Absolute:
        return 6
    case .Absolute_X:
        return 7
    }

    return 2
}
