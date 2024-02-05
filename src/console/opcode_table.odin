package console

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

	opcode_table[0x08] = Opcode {
		name            = "PHP",
		addressing_mode = Addressing_Mode.Implied,
		action          = php, // please no,
	}

	opcode_table[0x10] = Opcode {
		name            = "BPL",
		addressing_mode = Addressing_Mode.Relative,
		action          = bpl,
	}

	opcode_table[0x18] = Opcode {
		name            = "CLC",
		addressing_mode = Addressing_Mode.Implied,
		action          = clc,
	}

	opcode_table[0x20] = Opcode {
		name            = "JSR",
		addressing_mode = Addressing_Mode.Absolute,
		action          = jsr,
	}

	opcode_table[0x21] = Opcode {
		name            = "AND",
		addressing_mode = Addressing_Mode.Indexed_Indirect,
		action          = and,
	}

	opcode_table[0x24] = Opcode {
		name            = "BIT",
		addressing_mode = Addressing_Mode.Zero_Page,
		action          = bit,
	}

	opcode_table[0x25] = Opcode {
		name            = "AND",
		addressing_mode = Addressing_Mode.Zero_Page,
		action          = and,
	}

	opcode_table[0x29] = Opcode {
		name            = "AND",
		addressing_mode = Addressing_Mode.Immediate,
		action          = and,
	}

	opcode_table[0x2c] = Opcode {
		name            = "BIT",
		addressing_mode = Addressing_Mode.Absolute,
		action          = bit,
	}

	opcode_table[0x2d] = Opcode {
		name            = "AND",
		addressing_mode = Addressing_Mode.Absolute,
		action          = and,
	}

	opcode_table[0x31] = Opcode {
		name            = "AND",
		addressing_mode = Addressing_Mode.Indirect_Indexed,
		action          = and,
	}

	opcode_table[0x35] = Opcode {
		name            = "AND",
		addressing_mode = Addressing_Mode.Zero_Page_X,
		action          = and,
	}

	opcode_table[0x38] = Opcode {
		name            = "SEC",
		addressing_mode = Addressing_Mode.Implied,
		action          = sec,
	}

	opcode_table[0x39] = Opcode {
		name            = "AND",
		addressing_mode = Addressing_Mode.Absolute_Y,
		action          = and,
	}

	opcode_table[0x3d] = Opcode {
		name            = "AND",
		addressing_mode = Addressing_Mode.Absolute_X,
		action          = and,
	}

	opcode_table[0x4c] = Opcode {
		name            = "JMP",
		addressing_mode = Addressing_Mode.Absolute,
		action          = jmp,
	}

	opcode_table[0x50] = Opcode {
		name            = "BVC",
		addressing_mode = Addressing_Mode.Relative,
		action          = bvc,
	}

	opcode_table[0x60] = Opcode {
		name            = "RTS",
		addressing_mode = Addressing_Mode.Implied,
		action          = rts,
	}

	opcode_table[0x68] = Opcode {
		name            = "PLA",
		addressing_mode = Addressing_Mode.Implied,
		action          = pla,
	}

	opcode_table[0x70] = Opcode {
		name            = "BVS",
		addressing_mode = Addressing_Mode.Relative,
		action          = bvs,
	}

	opcode_table[0x78] = Opcode {
		name            = "SEI",
		addressing_mode = Addressing_Mode.Implied,
		action          = sei,
	}

	opcode_table[0x81] = Opcode {
		name            = "STA",
		addressing_mode = Addressing_Mode.Indexed_Indirect,
		action          = sta,
	}

	opcode_table[0x85] = Opcode {
		name            = "STA",
		addressing_mode = Addressing_Mode.Zero_Page,
		action          = sta,
	}

	opcode_table[0x86] = Opcode {
		name            = "STX",
		addressing_mode = Addressing_Mode.Zero_Page,
		action          = stx,
	}

	opcode_table[0x8d] = Opcode {
		name            = "STA",
		addressing_mode = Addressing_Mode.Absolute,
		action          = sta,
	}

	opcode_table[0x90] = Opcode {
		name            = "BCC",
		addressing_mode = Addressing_Mode.Relative,
		action          = bcc,
	}

	opcode_table[0x91] = Opcode {
		name            = "STA",
		addressing_mode = Addressing_Mode.Indirect_Indexed,
		action          = sta,
	}

	opcode_table[0x95] = Opcode {
		name            = "STA",
		addressing_mode = Addressing_Mode.Zero_Page_X,
		action          = sta,
	}

	opcode_table[0x9d] = Opcode {
		name            = "STA",
		addressing_mode = Addressing_Mode.Absolute_X,
		action          = sta,
	}

	opcode_table[0x99] = Opcode {
		name            = "STA",
		addressing_mode = Addressing_Mode.Absolute_Y,
		action          = sta,
	}

	opcode_table[0xa2] = Opcode {
		name            = "LDX",
		addressing_mode = Addressing_Mode.Immediate,
		action          = ldx,
	}

	opcode_table[0xa9] = Opcode {
		name            = "LDA",
		addressing_mode = Addressing_Mode.Immediate,
		action          = lda,
	}

	opcode_table[0xb0] = Opcode {
		name            = "BCS",
		addressing_mode = Addressing_Mode.Relative,
		action          = bcs,
	}

	opcode_table[0xd0] = Opcode {
		name            = "BNE",
		addressing_mode = Addressing_Mode.Relative,
		action          = bne,
	}

	opcode_table[0xea] = Opcode {
		name            = "NOP",
		addressing_mode = Addressing_Mode.Implied,
		action          = nop,
	}

	opcode_table[0xf0] = Opcode {
		name            = "BEQ",
		addressing_mode = Addressing_Mode.Relative,
		action          = beq,
	}

	opcode_table[0xf8] = Opcode {
		name            = "SED",
		addressing_mode = Addressing_Mode.Implied,
		action          = sed,
	}

	return opcode_table
}
