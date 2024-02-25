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

    opcode_table[0x01] = Opcode {
        name            = "ORA",
        addressing_mode = Addressing_Mode.Indexed_Indirect,
        action          = ora,
    }

    opcode_table[0x05] = Opcode {
        name            = "ORA",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = ora,
    }

    opcode_table[0x06] = Opcode {
        name            = "ASL",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = asl,
    }

    opcode_table[0x08] = Opcode {
        name            = "PHP",
        addressing_mode = Addressing_Mode.Implied,
        action          = php, // please no,
    }

    opcode_table[0x09] = Opcode {
        name            = "ORA",
        addressing_mode = Addressing_Mode.Immediate,
        action          = ora,
    }

    opcode_table[0x0a] = Opcode {
        name            = "ASL",
        addressing_mode = Addressing_Mode.Accumulator,
        action          = asl,
    }

    opcode_table[0x0d] = Opcode {
        name            = "ORA",
        addressing_mode = Addressing_Mode.Absolute,
        action          = ora,
    }

    opcode_table[0x0e] = Opcode {
        name            = "ASL",
        addressing_mode = Addressing_Mode.Absolute,
        action          = asl,
    }

    opcode_table[0x10] = Opcode {
        name            = "BPL",
        addressing_mode = Addressing_Mode.Relative,
        action          = bpl,
    }

    opcode_table[0x11] = Opcode {
        name            = "ORA",
        addressing_mode = Addressing_Mode.Indirect_Indexed,
        action          = ora,
    }

    opcode_table[0x15] = Opcode {
        name            = "ORA",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = ora,
    }

    opcode_table[0x16] = Opcode {
        name            = "ASL",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = asl,
    }

    opcode_table[0x18] = Opcode {
        name            = "CLC",
        addressing_mode = Addressing_Mode.Implied,
        action          = clc,
    }

    opcode_table[0x19] = Opcode {
        name            = "ORA",
        addressing_mode = Addressing_Mode.Absolute_Y,
        action          = ora,
    }

    opcode_table[0x1a] = Opcode {
        name = "NOP",
        addressing_mode = Addressing_Mode.Implied,
        action = nop,
    }

    opcode_table[0x1d] = Opcode {
        name            = "ORA",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = ora,
    }

    opcode_table[0x1e] = Opcode {
        name            = "ASL",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = asl,
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

    opcode_table[0x26] = Opcode {
        name            = "ROL",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = rol,
    }

    opcode_table[0x28] = Opcode {
        name            = "PLP",
        addressing_mode = Addressing_Mode.Implied,
        action          = plp,
    }

    opcode_table[0x29] = Opcode {
        name            = "AND",
        addressing_mode = Addressing_Mode.Immediate,
        action          = and,
    }

    opcode_table[0x2a] = Opcode {
        name            = "ROL",
        addressing_mode = Addressing_Mode.Accumulator,
        action          = rol,
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

    opcode_table[0x2e] = Opcode {
        name            = "ROL",
        addressing_mode = Addressing_Mode.Absolute,
        action          = rol,
    }

    opcode_table[0x30] = Opcode {
        name            = "BMI",
        addressing_mode = Addressing_Mode.Relative,
        action          = bmi,
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

    opcode_table[0x36] = Opcode {
        name            = "ROL",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = rol,
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

    opcode_table[0x3a] = Opcode {
        name = "NOP",
        addressing_mode = Addressing_Mode.Implied,
        action = nop,
    }

    opcode_table[0x3d] = Opcode {
        name            = "AND",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = and,
    }

    opcode_table[0x3e] = Opcode {
        name            = "ROL",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = rol,
    }

    opcode_table[0x40] = Opcode {
        name            = "RTI",
        addressing_mode = Addressing_Mode.Implied,
        action          = rti,
    }

    opcode_table[0x41] = Opcode {
        name            = "EOR",
        addressing_mode = Addressing_Mode.Indexed_Indirect,
        action          = eor,
    }

    opcode_table[0x45] = Opcode {
        name            = "EOR",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = eor,
    }

    opcode_table[0x46] = Opcode {
        name            = "LSR",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = lsr,
    }

    opcode_table[0x48] = Opcode {
        name            = "PHA",
        addressing_mode = Addressing_Mode.Implied,
        action          = pha,
    }

    opcode_table[0x49] = Opcode {
        name            = "EOR",
        addressing_mode = Addressing_Mode.Immediate,
        action          = eor,
    }

    opcode_table[0x4a] = Opcode {
        name            = "LSR",
        addressing_mode = Addressing_Mode.Accumulator,
        action          = lsr,
    }

    opcode_table[0x4c] = Opcode {
        name            = "JMP",
        addressing_mode = Addressing_Mode.Absolute,
        action          = jmp,
    }

    opcode_table[0x4d] = Opcode {
        name            = "EOR",
        addressing_mode = Addressing_Mode.Absolute,
        action          = eor,
    }

    opcode_table[0x4e] = Opcode {
        name            = "LSR",
        addressing_mode = Addressing_Mode.Absolute,
        action          = lsr,
    }

    opcode_table[0x50] = Opcode {
        name            = "BVC",
        addressing_mode = Addressing_Mode.Relative,
        action          = bvc,
    }

    opcode_table[0x51] = Opcode {
        name            = "EOR",
        addressing_mode = Addressing_Mode.Indirect_Indexed,
        action          = eor,
    }

    opcode_table[0x55] = Opcode {
        name            = "EOR",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = eor,
    }

    opcode_table[0x56] = Opcode {
        name            = "LSR",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = lsr,
    }

    opcode_table[0x59] = Opcode {
        name            = "EOR",
        addressing_mode = Addressing_Mode.Absolute_Y,
        action          = eor,
    }

    opcode_table[0x5a] = Opcode {
        name = "NOP",
        addressing_mode = Addressing_Mode.Implied,
        action = nop,
    }

    opcode_table[0x5d] = Opcode {
        name            = "EOR",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = eor,
    }

    opcode_table[0x5e] = Opcode {
        name            = "LSR",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = lsr,
    }

    opcode_table[0x60] = Opcode {
        name            = "RTS",
        addressing_mode = Addressing_Mode.Implied,
        action          = rts,
    }

    opcode_table[0x61] = Opcode {
        name            = "ADC",
        addressing_mode = Addressing_Mode.Indexed_Indirect,
        action          = adc,
    }

    opcode_table[0x65] = Opcode {
        name            = "ADC",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = adc,
    }

    opcode_table[0x66] = Opcode {
        name            = "ROR",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = ror,
    }

    opcode_table[0x68] = Opcode {
        name            = "PLA",
        addressing_mode = Addressing_Mode.Implied,
        action          = pla,
    }

    opcode_table[0x69] = Opcode {
        name            = "ADC",
        addressing_mode = Addressing_Mode.Immediate,
        action          = adc,
    }

    opcode_table[0x6a] = Opcode {
        name            = "ROR",
        addressing_mode = Addressing_Mode.Accumulator,
        action          = ror,
    }

    opcode_table[0x6c] = Opcode {
        name            = "JMP",
        addressing_mode = Addressing_Mode.Indirect,
        action          = jmp,
    }

    opcode_table[0x6d] = Opcode {
        name            = "ADC",
        addressing_mode = Addressing_Mode.Absolute,
        action          = adc,
    }

    opcode_table[0x6e] = Opcode {
        name            = "ROR",
        addressing_mode = Addressing_Mode.Absolute,
        action          = ror,
    }

    opcode_table[0x71] = Opcode {
        name            = "ADC",
        addressing_mode = Addressing_Mode.Indirect_Indexed,
        action          = adc,
    }

    opcode_table[0x70] = Opcode {
        name            = "BVS",
        addressing_mode = Addressing_Mode.Relative,
        action          = bvs,
    }

    opcode_table[0x75] = Opcode {
        name            = "ADC",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = adc,
    }

    opcode_table[0x76] = Opcode {
        name            = "ROR",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = ror,
    }

    opcode_table[0x78] = Opcode {
        name            = "SEI",
        addressing_mode = Addressing_Mode.Implied,
        action          = sei,
    }

    opcode_table[0x79] = Opcode {
        name            = "ADC",
        addressing_mode = Addressing_Mode.Absolute_Y,
        action          = adc,
    }

    opcode_table[0x7a] = Opcode {
        name = "NOP",
        addressing_mode = Addressing_Mode.Implied,
        action = nop,
    }

    opcode_table[0x7d] = Opcode {
        name            = "ADC",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = adc,
    }

    opcode_table[0x7e] = Opcode {
        name            = "ROR",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = ror,
    }

    opcode_table[0x81] = Opcode {
        name            = "STA",
        addressing_mode = Addressing_Mode.Indexed_Indirect,
        action          = sta,
    }

    opcode_table[0x84] = Opcode {
        name            = "STY",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = sty,
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

    opcode_table[0x88] = Opcode {
        name            = "DEY",
        addressing_mode = Addressing_Mode.Implied,
        action          = dey,
    }

    opcode_table[0x8a] = Opcode {
        name            = "TXA",
        addressing_mode = Addressing_Mode.Implied,
        action          = txa,
    }

    opcode_table[0x8c] = Opcode {
        name            = "STY",
        addressing_mode = Addressing_Mode.Absolute,
        action          = sty,
    }

    opcode_table[0x8d] = Opcode {
        name            = "STA",
        addressing_mode = Addressing_Mode.Absolute,
        action          = sta,
    }

    opcode_table[0x8e] = Opcode {
        name            = "STX",
        addressing_mode = Addressing_Mode.Absolute,
        action          = stx,
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

    opcode_table[0x94] = Opcode {
        name            = "STY",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = sty,
    }

    opcode_table[0x95] = Opcode {
        name            = "STA",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = sta,
    }

    opcode_table[0x96] = Opcode {
        name            = "STX",
        addressing_mode = Addressing_Mode.Zero_Page_Y,
        action          = stx,
    }

    opcode_table[0x9a] = Opcode {
        name            = "TXS",
        addressing_mode = Addressing_Mode.Implied,
        action          = txs,
    }

    opcode_table[0x9d] = Opcode {
        name            = "STA",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = sta,
    }

    opcode_table[0x98] = Opcode {
        name            = "TYA",
        addressing_mode = Addressing_Mode.Implied,
        action          = tya,
    }

    opcode_table[0x99] = Opcode {
        name            = "STA",
        addressing_mode = Addressing_Mode.Absolute_Y,
        action          = sta,
    }

    opcode_table[0xa0] = Opcode {
        name            = "LDY",
        addressing_mode = Addressing_Mode.Immediate,
        action          = ldy,
    }

    opcode_table[0xa1] = Opcode {
        name            = "LDA",
        addressing_mode = Addressing_Mode.Indexed_Indirect,
        action          = lda,
    }

    opcode_table[0xa2] = Opcode {
        name            = "LDX",
        addressing_mode = Addressing_Mode.Immediate,
        action          = ldx,
    }

    opcode_table[0xa4] = Opcode {
        name            = "LDY",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = ldy,
    }

    opcode_table[0xa5] = Opcode {
        name            = "LDA",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = lda,
    }

    opcode_table[0xa6] = Opcode {
        name            = "LDX",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = ldx,
    }

    opcode_table[0xa8] = Opcode {
        name            = "TAY",
        addressing_mode = Addressing_Mode.Implied,
        action          = tay,
    }

    opcode_table[0xa9] = Opcode {
        name            = "LDA",
        addressing_mode = Addressing_Mode.Immediate,
        action          = lda,
    }

    opcode_table[0xaa] = Opcode {
        name            = "TAX",
        addressing_mode = Addressing_Mode.Implied,
        action          = tax,
    }

    opcode_table[0xac] = Opcode {
        name            = "LDY",
        addressing_mode = Addressing_Mode.Absolute,
        action          = ldy,
    }

    opcode_table[0xad] = Opcode {
        name            = "LDA",
        addressing_mode = Addressing_Mode.Absolute,
        action          = lda,
    }

    opcode_table[0xae] = Opcode {
        name            = "LDX",
        addressing_mode = Addressing_Mode.Absolute,
        action          = ldx,
    }

    opcode_table[0xb0] = Opcode {
        name            = "BCS",
        addressing_mode = Addressing_Mode.Relative,
        action          = bcs,
    }

    opcode_table[0xb1] = Opcode {
        name            = "LDA",
        addressing_mode = Addressing_Mode.Indirect_Indexed,
        action          = lda,
    }

    opcode_table[0xb4] = Opcode {
        name            = "LDY",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = ldy,
    }

    opcode_table[0xb5] = Opcode {
        name            = "LDA",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = lda,
    }

    opcode_table[0xb6] = Opcode {
        name            = "LDX",
        addressing_mode = Addressing_Mode.Zero_Page_Y,
        action          = ldx,
    }

    opcode_table[0xb8] = Opcode {
        name            = "CLV",
        addressing_mode = Addressing_Mode.Implied,
        action          = clv,
    }

    opcode_table[0xb9] = Opcode {
        name            = "LDA",
        addressing_mode = Addressing_Mode.Absolute_Y,
        action          = lda,
    }

    opcode_table[0xba] = Opcode {
        name            = "TSX",
        addressing_mode = Addressing_Mode.Implied,
        action          = tsx,
    }

    opcode_table[0xbc] = Opcode {
        name            = "LDY",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = ldy,
    }

    opcode_table[0xbd] = Opcode {
        name            = "LDA",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = lda,
    }

    opcode_table[0xbe] = Opcode {
        name            = "LDX",
        addressing_mode = Addressing_Mode.Absolute_Y,
        action          = ldx,
    }

    opcode_table[0xc0] = Opcode {
        name            = "CPY",
        addressing_mode = Addressing_Mode.Immediate,
        action          = cpy,
    }

    opcode_table[0xc1] = Opcode {
        name            = "CMP",
        addressing_mode = Addressing_Mode.Indexed_Indirect,
        action          = cmp,
    }

    opcode_table[0xc4] = Opcode {
        name            = "CPY",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = cpy,
    }

    opcode_table[0xc5] = Opcode {
        name            = "CMP",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = cmp,
    }

    opcode_table[0xc6] = Opcode {
        name            = "DEC",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = dec,
    }

    opcode_table[0xc8] = Opcode {
        name            = "INY",
        addressing_mode = Addressing_Mode.Implied,
        action          = iny,
    }

    opcode_table[0xc9] = Opcode {
        name            = "CMP",
        addressing_mode = Addressing_Mode.Immediate,
        action          = cmp,
    }

    opcode_table[0xca] = Opcode {
        name            = "DEX",
        addressing_mode = Addressing_Mode.Implied,
        action          = dex,
    }

    opcode_table[0xcc] = Opcode {
        name            = "CPY",
        addressing_mode = Addressing_Mode.Absolute,
        action          = cpy,
    }

    opcode_table[0xcd] = Opcode {
        name            = "CMP",
        addressing_mode = Addressing_Mode.Absolute,
        action          = cmp,
    }

    opcode_table[0xce] = Opcode {
        name            = "DEC",
        addressing_mode = Addressing_Mode.Absolute,
        action          = dec,
    }

    opcode_table[0xd0] = Opcode {
        name            = "BNE",
        addressing_mode = Addressing_Mode.Relative,
        action          = bne,
    }

    opcode_table[0xd1] = Opcode {
        name            = "CMP",
        addressing_mode = Addressing_Mode.Indirect_Indexed,
        action          = cmp,
    }

    opcode_table[0xd8] = Opcode {
        name            = "CLD",
        addressing_mode = Addressing_Mode.Implied,
        action          = cld,
    }

    opcode_table[0xd5] = Opcode {
        name            = "CMP",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = cmp,
    }

    opcode_table[0xd6] = Opcode {
        name            = "DEC",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = dec,
    }

    opcode_table[0xda] = Opcode {
        name = "NOP",
        addressing_mode = Addressing_Mode.Implied,
        action = nop,
    }

    opcode_table[0xdd] = Opcode {
        name            = "CMP",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = cmp,
    }

    opcode_table[0xde] = Opcode {
        name            = "DEC",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = dec,
    }

    opcode_table[0xd9] = Opcode {
        name            = "CMP",
        addressing_mode = Addressing_Mode.Absolute_Y,
        action          = cmp,
    }

    opcode_table[0xe0] = Opcode {
        name            = "CPX",
        addressing_mode = Addressing_Mode.Immediate,
        action          = cpx,
    }

    opcode_table[0xe1] = Opcode {
        name            = "SBC",
        addressing_mode = Addressing_Mode.Indexed_Indirect,
        action          = sbc,
    }

    opcode_table[0xe4] = Opcode {
        name            = "CPX",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = cpx,
    }

    opcode_table[0xe5] = Opcode {
        name            = "SBC",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = sbc,
    }

    opcode_table[0xe6] = Opcode {
        name            = "INC",
        addressing_mode = Addressing_Mode.Zero_Page,
        action          = inc,
    }

    opcode_table[0xe8] = Opcode {
        name            = "INX",
        addressing_mode = Addressing_Mode.Implied,
        action          = inx,
    }

    opcode_table[0xe9] = Opcode {
        name            = "SBC",
        addressing_mode = Addressing_Mode.Immediate,
        action          = sbc,
    }

    opcode_table[0xea] = Opcode {
        name            = "NOP",
        addressing_mode = Addressing_Mode.Implied,
        action          = nop,
    }

    opcode_table[0xec] = Opcode {
        name            = "CPX",
        addressing_mode = Addressing_Mode.Absolute,
        action          = cpx,
    }

    opcode_table[0xed] = Opcode {
        name            = "SBC",
        addressing_mode = Addressing_Mode.Absolute,
        action          = sbc,
    }

    opcode_table[0xee] = Opcode {
        name            = "INC",
        addressing_mode = Addressing_Mode.Absolute,
        action          = inc,
    }

    opcode_table[0xf0] = Opcode {
        name            = "BEQ",
        addressing_mode = Addressing_Mode.Relative,
        action          = beq,
    }

    opcode_table[0xf1] = Opcode {
        name            = "SBC",
        addressing_mode = Addressing_Mode.Indirect_Indexed,
        action          = sbc,
    }

    opcode_table[0xf5] = Opcode {
        name            = "SBC",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = sbc,
    }

    opcode_table[0xf6] = Opcode {
        name            = "INC",
        addressing_mode = Addressing_Mode.Zero_Page_X,
        action          = inc,
    }

    opcode_table[0xf8] = Opcode {
        name            = "SED",
        addressing_mode = Addressing_Mode.Implied,
        action          = sed,
    }

    opcode_table[0xf9] = Opcode {
        name            = "SBC",
        addressing_mode = Addressing_Mode.Absolute_Y,
        action          = sbc,
    }

    opcode_table[0xfa] = Opcode {
        name = "NOP",
        addressing_mode = Addressing_Mode.Implied,
        action = nop,
    }

    opcode_table[0xfd] = Opcode {
        name            = "SBC",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = sbc,
    }

    opcode_table[0xfe] = Opcode {
        name            = "INC",
        addressing_mode = Addressing_Mode.Absolute_X,
        action          = inc,
    }

    return opcode_table
}
