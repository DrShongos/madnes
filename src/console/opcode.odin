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

trace_opcode :: proc(opcode: ^Opcode, cpu: ^CPU) {
	fmt.printf("%x %x ", cpu.program_counter, cpu.memory[cpu.program_counter])

	#partial switch opcode.addressing_mode {
	case .Implied:
		fmt.printf("      ")
	case .Immediate, .Zero_Page, .Zero_Page_Y, .Zero_Page_X, .Indexed_Indirect, .Indirect_Indexed, .Relative:
		fmt.printf("%x    ", cpu.memory[cpu.program_counter + 1])
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
			"$%x   ",
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
	case .Relative:
		fmt.printf("*.%d ", i8(cpu.memory[cpu.program_counter + 1]))
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

execute_opcode :: proc(opcode: ^Opcode, cpu: ^CPU) -> u8 {
	trace_opcode(opcode, cpu)
	return opcode.action(cpu, opcode.addressing_mode)
}

zero_page_wrap :: proc(mem: u16, add: u16, cpu: ^CPU) -> u16 {
	new_address := mem + add

	if new_address > 0xFF {
		cpu.page_crossed = true
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
		new_address := address + u16(cpu.register_x)
		if address & 0xFF00 < new_address & 0xFF00 || address & 0xFF00 > new_address & 0xFF00 {
			cpu.page_crossed = true
		}
		return u16_to_u8(address)
	case .Absolute_Y:
		address := u8_to_u16(cpu_fetch(cpu), cpu_fetch(cpu))
		new_address := address + u16(cpu.register_y)
		if address & 0xFF00 < new_address & 0xFF00 || address & 0xFF00 > new_address & 0xFF00 {
			cpu.page_crossed = true
		}
		return u16_to_u8(address)
	case .Indirect:
		hi := cpu_fetch(cpu)
		lo := cpu_fetch(cpu)

		lo_address := u8_to_u16(hi, lo)
		real_lo := cpu.memory[lo_address]
		return hi, real_lo
	case .Indexed_Indirect:
		address := u8_to_u16(cpu_fetch(cpu), 0x00)
		new_address := zero_page_wrap(address, u16(cpu.register_x), cpu)

		return u16_to_u8(new_address)
	case .Indirect_Indexed:
		address := u8_to_u16(cpu_fetch(cpu), 0x00)
		new_address := zero_page_wrap(address, u16(cpu.register_y), cpu)

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

lda :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	hi, lo := read_memory(addressing_mode, cpu)

	new_a := hi
	if addressing_mode != .Immediate {
		new_a = cpu.memory[u8_to_u16(hi, lo)]
	}

	cpu.accumulator = new_a

	if new_a == 0 {
		cpu.status += {.Zero}
	} else {
		cpu.status -= {.Zero}
	}


	if new_a & 0b10000000 != 0 {
		cpu.status += {.Negative}
	} else {
		cpu.status -= {.Negative}
	}


	cpu_fetch(cpu)

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

ldx :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	hi, lo := read_memory(addressing_mode, cpu)

	new_x := hi
	if addressing_mode != .Immediate {
		new_x = cpu.memory[u8_to_u16(hi, lo)]
	}

	cpu.register_x = new_x

	if new_x == 0 {
		cpu.status += {.Zero}
	} else {
		cpu.status -= {.Zero}
	}

	if new_x & 0b10000000 != 0 {
		cpu.status += {.Negative}
	} else {
		cpu.status -= {.Negative}
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

sta :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	addr_hi, addr_lo := read_memory(addressing_mode, cpu)
	address: u16 = u8_to_u16(addr_hi, addr_lo)

	cpu.memory[address] = cpu.accumulator
	cpu_fetch(cpu)

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

jmp :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	jump_hi, jump_lo := read_memory(addressing_mode, cpu)
	cpu.program_counter = u8_to_u16(jump_hi, jump_lo)

	#partial switch addressing_mode {
	case .Absolute:
		return 3
	}

	return 5
}

jsr :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	addr_hi, addr_lo := read_memory(addressing_mode, cpu)
	address := u8_to_u16(addr_hi, addr_lo)

	// The return point of the subroutine will be the address of the LSB, 
	// which the program counter is pointing towards now
	pc_hi, pc_lo := u16_to_u8(cpu.program_counter)

	stack_push(cpu, pc_lo)
	stack_push(cpu, pc_hi)

	cpu.program_counter = address

	return 6
}

rts :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	hi := stack_pop(cpu)
	lo := stack_pop(cpu)

	return_address := u8_to_u16(hi, lo)
	cpu.program_counter = return_address
	cpu_fetch(cpu)

	return 6
}

bit :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	hi, lo := read_memory(addressing_mode, cpu)
	addr := u8_to_u16(hi, lo)

	test_val := cpu.memory[addr]

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

	cpu_fetch(cpu)

	if addressing_mode == .Zero_Page {
		return 3
	}
	return 4
}

and :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	test_val: u8 = 0

	hi, lo := read_memory(addressing_mode, cpu)
	addr := u8_to_u16(hi, lo)

	test_val = cpu.memory[addr]
	if addressing_mode == .Immediate {
		test_val = hi
	}

	cpu.accumulator &= test_val

	if cpu.accumulator == 0 {
		cpu.status += {.Zero}
	} else {
		cpu.status -= {.Zero}
	}

	if cpu.accumulator & 0b10000000 != 0 {
		cpu.status += {.Negative}
	} else {
		cpu.status -= {.Negative}
	}

	cpu_fetch(cpu)

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

bcs :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	offset_hi, offset_lo := read_memory(addressing_mode, cpu)
	pc_move := u8_to_u16(offset_hi, offset_lo)

	if .Carry in cpu.status {
		prev_pc := cpu.program_counter
		cpu.program_counter = pc_move
		cpu_fetch(cpu)

		if (pc_move & 0xFF00) > (prev_pc & 0xFF00) || (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
			return 5
		}
		return 3
	}

	cpu_fetch(cpu)
	return 2
}

bvs :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	offset_hi, offset_lo := read_memory(addressing_mode, cpu)
	pc_move := u8_to_u16(offset_hi, offset_lo)

	if .Overflow in cpu.status {
		prev_pc := cpu.program_counter
		cpu.program_counter = pc_move
		cpu_fetch(cpu)

		if (pc_move & 0xFF00) > (prev_pc & 0xFF00) || (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
			return 5
		}
		return 3
	}

	cpu_fetch(cpu)
	return 2
}

bvc :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	offset_hi, offset_lo := read_memory(addressing_mode, cpu)
	pc_move := u8_to_u16(offset_hi, offset_lo)

	if !(.Overflow in cpu.status) {
		prev_pc := cpu.program_counter
		cpu.program_counter = pc_move
		cpu_fetch(cpu)

		if (pc_move & 0xFF00) > (prev_pc & 0xFF00) || (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
			return 5
		}
		return 3
	}

	cpu_fetch(cpu)
	return 2
}

bcc :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	offset_hi, offset_lo := read_memory(addressing_mode, cpu)
	pc_move := u8_to_u16(offset_hi, offset_lo)

	if !(.Carry in cpu.status) {
		prev_pc := cpu.program_counter
		cpu.program_counter = pc_move
		cpu_fetch(cpu)

		if (pc_move & 0xFF00) > (prev_pc & 0xFF00) || (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
			return 5
		}
		return 3
	}

	cpu_fetch(cpu)
	return 2
}

beq :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	offset_hi, offset_lo := read_memory(addressing_mode, cpu)
	pc_move := u8_to_u16(offset_hi, offset_lo)

	if .Zero in cpu.status {
		prev_pc := cpu.program_counter
		cpu.program_counter = pc_move
		cpu_fetch(cpu)

		if (pc_move & 0xFF00) > (prev_pc & 0xFF00) || (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
			return 5
		}
		return 3
	}

	cpu_fetch(cpu)
	return 2
}

bne :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	offset_hi, offset_lo := read_memory(addressing_mode, cpu)
	pc_move := u8_to_u16(offset_hi, offset_lo)

	if !(.Zero in cpu.status) {
		prev_pc := cpu.program_counter
		cpu.program_counter = pc_move
		cpu_fetch(cpu)

		if (pc_move & 0xFF00) > (prev_pc & 0xFF00) || (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
			return 5
		}
		return 3
	}

	cpu_fetch(cpu)
	return 2
}

bpl :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	offset_hi, offset_lo := read_memory(addressing_mode, cpu)
	pc_move := u8_to_u16(offset_hi, offset_lo)

	if !(.Negative in cpu.status) {
		prev_pc := cpu.program_counter
		cpu.program_counter = pc_move
		cpu_fetch(cpu)

		if (pc_move & 0xFF00) > (prev_pc & 0xFF00) || (pc_move & 0xFF00) < (prev_pc & 0xFF00) {
			return 5
		}
		return 3
	}

	cpu_fetch(cpu)
	return 2
}

sec :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	cpu.status += {.Carry}
	cpu_fetch(cpu)
	return 2
}

sei :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	cpu.status += {.Interrupt_Disable}
	cpu_fetch(cpu)
	return 2
}

sed :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	cpu.status += {.Decimal_Mode}
	cpu_fetch(cpu)
	return 2
}

clc :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	cpu.status -= {.Carry}
	cpu_fetch(cpu)
	return 2
}

nop :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	cpu_fetch(cpu)
	return 2
}

php :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	stack_push(cpu, transmute(u8)cpu.status)
	cpu_fetch(cpu)
	return 3
}

pla :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
	cpu.accumulator = stack_pop(cpu)

	if cpu.accumulator == 0 {
		cpu.status += {.Zero}
	} else {
		cpu.status -= {.Zero}
	}

	if cpu.accumulator & 0b10000000 != 0 {
		cpu.status += {.Negative}
	} else {
		cpu.status -= {.Negative}
	}

	cpu_fetch(cpu)

	return 4
}
