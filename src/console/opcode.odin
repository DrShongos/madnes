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
	action:          proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8,
}

create_opcode_table :: proc() -> [OPCODE_TABLE_SIZE]Opcode {
	opcode_table := [OPCODE_TABLE_SIZE]Opcode{}

	for i := 0; i < OPCODE_TABLE_SIZE; i += 1 {
		opcode_table[i] = Opcode {
			name            = "INVALID",
			addressing_mode = Addressing_Mode.Implied,
			action          = invalid,
		}
	}

	opcode_table[0] = Opcode {
		name            = "BRK",
		addressing_mode = Addressing_Mode.Implied,
		action          = brk,
	}

	opcode_table[0x4c] = Opcode {
		name            = "JMP",
		addressing_mode = Addressing_Mode.Absolute,
		action          = jmp,
	}

	opcode_table[0x86] = Opcode {
		name            = "STX",
		addressing_mode = Addressing_Mode.Zero_Page,
		action          = stx,
	}

	opcode_table[0xa2] = Opcode {
		name            = "LDX",
		addressing_mode = Addressing_Mode.Immediate,
		action          = ldx,
	}

	return opcode_table
}

trace_opcode :: proc(opcode: ^Opcode, cpu: ^CPU) {
	fmt.printf("%x %x ", cpu.program_counter, cpu.memory[cpu.program_counter])

	#partial switch opcode.addressing_mode {
	case .Immediate, .Zero_Page, .Zero_Page_Y, .Zero_Page_X, .Indexed_Indirect, .Indirect_Indexed:
		fmt.printf("%x ", cpu.memory[cpu.program_counter + 1])
	case .Absolute, .Absolute_X, .Absolute_Y, .Indirect:
		fmt.printf(
			"%x %x ",
			cpu.memory[cpu.program_counter + 1],
			cpu.memory[cpu.program_counter + 2],
		)
	}

	fmt.printf("  ")

	fmt.printf("%s ", opcode.name)
	#partial switch opcode.addressing_mode {
	case .Absolute:
		fmt.printf(
			"$%x ",
			u8_to_u16(cpu.memory[cpu.program_counter + 1], cpu.memory[cpu.program_counter + 2]),
		)
	case .Absolute_X:
		fmt.printf(
			"$%x,X ",
			u8_to_u16(cpu.memory[cpu.program_counter + 1], cpu.memory[cpu.program_counter + 2]),
		)
	case .Absolute_Y:
		fmt.printf(
			"$%x,Y ",
			u8_to_u16(cpu.memory[cpu.program_counter + 1], cpu.memory[cpu.program_counter + 2]),
		)
	case .Indirect:
		fmt.printf(
			"(%x) ",
			u8_to_u16(cpu.memory[cpu.program_counter + 1], cpu.memory[cpu.program_counter + 2]),
		)
	case .Accumulator:
		fmt.printf("A ")
	case .Immediate:
		fmt.printf("#%x ", cpu.memory[cpu.program_counter + 1])
	case .Zero_Page:
		fmt.printf("$%x ", cpu.memory[cpu.program_counter + 1])
	case .Zero_Page_X:
		fmt.printf("$%x,X ", cpu.memory[cpu.program_counter + 1])
	case .Zero_Page_Y:
		fmt.printf("$%x,Y ", cpu.memory[cpu.program_counter + 1])
	case .Indexed_Indirect:
		fmt.printf("($%x,X) ", cpu.memory[cpu.program_counter + 1])
	case .Indirect_Indexed:
		fmt.printf("($%x),Y ", cpu.memory[cpu.program_counter + 1])
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

execute_opcode :: proc(opcode: ^Opcode, cpu: ^CPU) -> u8 {
	trace_opcode(opcode, cpu)
	return opcode.action(cpu, opcode.addressing_mode)
}

zero_page_wrap :: proc(mem: u16, add: u16) -> u16 {
	new_address := mem + add

	if new_address > 0xFF {
		return new_address - 0xFF
	}

	return new_address
}

read_memory :: proc(mode: Addressing_Mode, cpu: ^CPU) -> (u8, u8) {
	#partial switch mode {
	case .Immediate:
		return cpu_fetch(cpu), 0
	case .Zero_Page:
		return cpu_fetch(cpu), 0
	case .Zero_Page_X:
		return cpu_fetch(cpu) + cpu.register_x, 0
	case .Zero_Page_Y:
		return cpu_fetch(cpu) + cpu.register_y, 0
	case .Relative:
		offset := i8(cpu_fetch(cpu))
		offset_pc := cpu.program_counter
		// This statement exists because the sign gets removed 
		// upon conversion to an unsigned integer
		if offset < 0 {
			// This will probably cause a bug later
			offset_pc -= (u16(offset) - 128)
		} else {
			offset_pc += u16(offset)
		}

		return u16_to_u8(offset_pc)
	case .Absolute:
		return cpu_fetch(cpu), cpu_fetch(cpu)
	case .Absolute_X:
		address := u8_to_u16(cpu_fetch(cpu), cpu_fetch(cpu))
		address += u16(cpu.register_x)
		return u16_to_u8(address)
	case .Absolute_Y:
		address := u8_to_u16(cpu_fetch(cpu), cpu_fetch(cpu))
		address += u16(cpu.register_y)
		return u16_to_u8(address)
	case .Indirect:
		hi := cpu_fetch(cpu)
		lo := cpu_fetch(cpu)

		lo_address := u8_to_u16(hi, lo)
		real_lo := cpu.memory[lo_address]
		return hi, real_lo
	case .Indexed_Indirect:
		address := u8_to_u16(cpu_fetch(cpu), 0x00)
		new_address := zero_page_wrap(address, u16(cpu.register_x))

		return u16_to_u8(new_address)
	case .Indirect_Indexed:
		address := u8_to_u16(cpu_fetch(cpu), 0x00)
		new_address := zero_page_wrap(address, u16(cpu.register_y))

		return u16_to_u8(new_address)
	}

	return 0, 0
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

ldx :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	hi, _ := read_memory(addressing_mode, cpu)

	cpu.register_x = hi

	if hi == 0 {
		cpu.status += {.Zero}
	}

	if hi & 0b10000000 != 0 {
		cpu.status += {.Negative}
	}

	cpu_fetch(cpu)

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

stx :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
    addr_hi, addr_lo := read_memory(addressing_mode, cpu)
	address: u16 = u8_to_u16(addr_hi, addr_lo)

	cpu.memory[address] = cpu.register_x
	cpu_fetch(cpu)

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

jmp :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	jump_hi, jump_lo := read_memory(addressing_mode, cpu)
	cpu.program_counter = u8_to_u16(jump_hi, jump_lo)

	#partial switch addressing_mode {
	case .Absolute:
		return 3
	}

	return 5
}


nop :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	return 2
}
