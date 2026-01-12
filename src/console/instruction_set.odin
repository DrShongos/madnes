package console

INSTRUCTION_SET_SIZE :: 0x100

Instruction_Code :: #type proc(
    cpu: ^CPU,
    addressing_mode: Instruction_Addressing_Mode,
)

/// The Instruction addressing mode specifies how the instruction obtains the data
/// necessary to execute itself.
/// The enum is used to keep track of the addressing mode for debugging purposes.
Instruction_Addressing_Mode :: enum {
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

Instruction :: struct {
    name:            string,
    addressing_mode: Instruction_Addressing_Mode,

    /// The procedure that defines the instruction's behaviour
    execute:         Instruction_Code,
}

instruction_set_create :: proc() -> [INSTRUCTION_SET_SIZE]Instruction {
    instruction_set := [INSTRUCTION_SET_SIZE]Instruction{}

    for i := 0; i < INSTRUCTION_SET_SIZE; i += 1 {
        instruction_set[i] = Instruction {
            "INVALID",
            .Implied,
            invalid_instruction,
        }
    }

    instruction_set[0x4c] = {"JMP", .Absolute, jmp}
    instruction_set[0x6c] = {"JMP", .Indirect, jmp}

    instruction_set[0xa2] = {"LDX", .Immediate, ldx}
    instruction_set[0xa6] = {"LDX", .Zero_Page, ldx}
    instruction_set[0xb6] = {"LDX", .Zero_Page_Y, ldx}
    instruction_set[0xae] = {"LDX", .Absolute, ldx}
    instruction_set[0xbe] = {"LDX", .Absolute_Y, ldx}

    instruction_set[0xa0] = {"LDY", .Immediate, ldy}
    instruction_set[0xa4] = {"LDY", .Zero_Page, ldy}
    instruction_set[0xb4] = {"LDY", .Zero_Page_X, ldy}
    instruction_set[0xac] = {"LDY", .Absolute, ldy}
    instruction_set[0xbc] = {"LDY", .Absolute_X, ldy}

    instruction_set[0xa9] = {"LDA", .Immediate, lda}
    instruction_set[0xa5] = {"LDA", .Zero_Page, lda}
    instruction_set[0xb5] = {"LDA", .Zero_Page_X, lda}
    instruction_set[0xad] = {"LDA", .Absolute, lda}
    instruction_set[0xbd] = {"LDA", .Absolute_X, lda}
    instruction_set[0xb9] = {"LDA", .Absolute_Y, lda}
    instruction_set[0xa1] = {"LDA", .Indexed_Indirect, lda}
    instruction_set[0xb1] = {"LDA", .Indirect_Indexed, lda}

    instruction_set[0x86] = {"STX", .Zero_Page, stx}
    instruction_set[0x96] = {"STX", .Zero_Page_Y, stx}
    instruction_set[0x8e] = {"STX", .Absolute, stx}

    instruction_set[0x84] = {"STY", .Zero_Page, sty}
    instruction_set[0x94] = {"STY", .Zero_Page_X, sty}
    instruction_set[0x8c] = {"STY", .Absolute, sty}

    instruction_set[0x85] = {"STA", .Zero_Page, sta}
    instruction_set[0x95] = {"STA", .Zero_Page_X, sta}
    instruction_set[0x8d] = {"STA", .Absolute, sta}
    instruction_set[0x9d] = {"STA", .Absolute_X, sta}
    instruction_set[0x99] = {"STA", .Absolute_Y, sta}
    instruction_set[0x81] = {"STA", .Indexed_Indirect, sta}
    instruction_set[0x91] = {"STA", .Indirect_Indexed, sta}

    instruction_set[0x20] = {"JSR", .Absolute, jsr}
    instruction_set[0x60] = {"RTS", .Implied, rts}
    instruction_set[0x40] = {"RTI", .Implied, rti}

    instruction_set[0xea] = {"NOP", .Implied, nop}

    instruction_set[0x38] = {"SEC", .Implied, sec}
    instruction_set[0x18] = {"CLC", .Implied, clc}

    instruction_set[0xb0] = {"BCS", .Relative, bcs}
    instruction_set[0x90] = {"BCC", .Relative, bcc}

    instruction_set[0xf0] = {"BEQ", .Relative, beq}
    instruction_set[0xd0] = {"BNE", .Relative, bne}

    instruction_set[0x24] = {"BIT", .Zero_Page, bit}
    instruction_set[0x2c] = {"BIT", .Absolute, bit}

    instruction_set[0x70] = {"BVS", .Relative, bvs}
    instruction_set[0x50] = {"BVC", .Relative, bvc}

    instruction_set[0x10] = {"BPL", .Relative, bpl}
    instruction_set[0x30] = {"BMI", .Relative, bmi}

    instruction_set[0x78] = {"SEI", .Implied, sei}

    instruction_set[0xf8] = {"SED", .Implied, sed}
    instruction_set[0xd8] = {"CLD", .Implied, cld}

    instruction_set[0x08] = {"PHP", .Implied, php}
    instruction_set[0x28] = {"PLP", .Implied, plp}
    instruction_set[0x48] = {"PHA", .Implied, pha}
    instruction_set[0x68] = {"PLA", .Implied, pla}

    instruction_set[0x29] = {"AND", .Immediate, and}
    instruction_set[0x25] = {"AND", .Zero_Page, and}
    instruction_set[0x35] = {"AND", .Zero_Page_X, and}
    instruction_set[0x2d] = {"AND", .Absolute, and}
    instruction_set[0x3d] = {"AND", .Absolute_X, and}
    instruction_set[0x39] = {"AND", .Absolute_Y, and}
    instruction_set[0x21] = {"AND", .Indexed_Indirect, and}
    instruction_set[0x31] = {"AND", .Indirect_Indexed, and}

    instruction_set[0x09] = {"ORA", .Immediate, ora}
    instruction_set[0x05] = {"ORA", .Zero_Page, ora}
    instruction_set[0x15] = {"ORA", .Zero_Page_X, ora}
    instruction_set[0x0d] = {"ORA", .Absolute, ora}
    instruction_set[0x1d] = {"ORA", .Absolute_X, ora}
    instruction_set[0x19] = {"ORA", .Absolute_Y, ora}
    instruction_set[0x01] = {"ORA", .Indexed_Indirect, ora}
    instruction_set[0x11] = {"ORA", .Indirect_Indexed, ora}

    instruction_set[0x49] = {"EOR", .Immediate, eor}
    instruction_set[0x45] = {"EOR", .Zero_Page, eor}
    instruction_set[0x55] = {"EOR", .Zero_Page_X, eor}
    instruction_set[0x4d] = {"EOR", .Absolute, eor}
    instruction_set[0x5d] = {"EOR", .Absolute_X, eor}
    instruction_set[0x59] = {"EOR", .Absolute_Y, eor}
    instruction_set[0x41] = {"EOR", .Indexed_Indirect, eor}
    instruction_set[0x51] = {"EOR", .Indirect_Indexed, eor}

    instruction_set[0x69] = {"ADC", .Immediate, adc}
    instruction_set[0x65] = {"ADC", .Zero_Page, adc}
    instruction_set[0x75] = {"ADC", .Zero_Page_X, adc}
    instruction_set[0x6d] = {"ADC", .Absolute, adc}
    instruction_set[0x7d] = {"ADC", .Absolute_X, adc}
    instruction_set[0x79] = {"ADC", .Absolute_Y, adc}
    instruction_set[0x61] = {"ADC", .Indexed_Indirect, adc}
    instruction_set[0x71] = {"ADC", .Indirect_Indexed, adc}

    instruction_set[0xe9] = {"SBC", .Immediate, sbc}
    instruction_set[0xe5] = {"SBC", .Zero_Page, sbc}
    instruction_set[0xf5] = {"SBC", .Zero_Page_X, sbc}
    instruction_set[0xed] = {"SBC", .Absolute, sbc}
    instruction_set[0xfd] = {"SBC", .Absolute_X, sbc}
    instruction_set[0xf9] = {"SBC", .Absolute_Y, sbc}
    instruction_set[0xe1] = {"SBC", .Indexed_Indirect, sbc}
    instruction_set[0xf1] = {"SBC", .Indirect_Indexed, sbc}

    instruction_set[0xc9] = {"CMP", .Immediate, cmp}
    instruction_set[0xc5] = {"CMP", .Zero_Page, cmp}
    instruction_set[0xd5] = {"CMP", .Zero_Page_X, cmp}
    instruction_set[0xcd] = {"CMP", .Absolute, cmp}
    instruction_set[0xdd] = {"CMP", .Absolute_X, cmp}
    instruction_set[0xd9] = {"CMP", .Absolute_Y, cmp}
    instruction_set[0xc1] = {"CMP", .Indexed_Indirect, cmp}
    instruction_set[0xd1] = {"CMP", .Indirect_Indexed, cmp}

    instruction_set[0xc0] = {"CPY", .Immediate, cpy}
    instruction_set[0xc4] = {"CPY", .Zero_Page, cpy}
    instruction_set[0xcc] = {"CPY", .Absolute, cpy}

    instruction_set[0xe0] = {"CPX", .Immediate, cpx}
    instruction_set[0xe4] = {"CPX", .Zero_Page, cpx}
    instruction_set[0xec] = {"CPX", .Absolute, cpx}

    instruction_set[0xb8] = {"CLV", .Implied, clv}

    instruction_set[0xc8] = {"INY", .Implied, iny}
    instruction_set[0xe8] = {"INX", .Implied, inx}

    instruction_set[0xe6] = {"INC", .Zero_Page, inc}
    instruction_set[0xf6] = {"INC", .Zero_Page_X, inc}
    instruction_set[0xee] = {"INC", .Absolute, inc}
    instruction_set[0xfe] = {"INC", .Absolute_X, inc}

    instruction_set[0x88] = {"DEY", .Implied, dey}
    instruction_set[0xca] = {"DEX", .Implied, dex}

    instruction_set[0xc6] = {"DEC", .Zero_Page, dec}
    instruction_set[0xd6] = {"DEC", .Zero_Page_X, dec}
    instruction_set[0xce] = {"DEC", .Absolute, dec}
    instruction_set[0xde] = {"DEC", .Absolute_X, dec}

    instruction_set[0xaa] = {"TAX", .Implied, tax}
    instruction_set[0xa8] = {"TAY", .Implied, tay}
    instruction_set[0xba] = {"TSX", .Implied, tsx}
    instruction_set[0x8a] = {"TXA", .Implied, txa}
    instruction_set[0x9a] = {"TXS", .Implied, txs}
    instruction_set[0x98] = {"TYA", .Implied, tya}

    instruction_set[0x4a] = {"LSR", .Accumulator, lsr}
    instruction_set[0x46] = {"LSR", .Zero_Page, lsr}
    instruction_set[0x56] = {"LSR", .Zero_Page_X, lsr}
    instruction_set[0x4e] = {"LSR", .Absolute, lsr}
    instruction_set[0x5e] = {"LSR", .Absolute_X, lsr}

    instruction_set[0x0a] = {"ASL", .Accumulator, asl}
    instruction_set[0x06] = {"ASL", .Zero_Page, asl}
    instruction_set[0x16] = {"ASL", .Zero_Page_X, asl}
    instruction_set[0x0e] = {"ASL", .Absolute, asl}
    instruction_set[0x1e] = {"ASL", .Absolute_X, asl}

    instruction_set[0x6a] = {"ROR", .Accumulator, ror}
    instruction_set[0x66] = {"ROR", .Zero_Page, ror}
    instruction_set[0x76] = {"ROR", .Zero_Page_X, ror}
    instruction_set[0x6e] = {"ROR", .Absolute, ror}
    instruction_set[0x7e] = {"ROR", .Absolute_X, ror}

    instruction_set[0x2a] = {"ROL", .Accumulator, rol}
    instruction_set[0x26] = {"ROL", .Zero_Page, rol}
    instruction_set[0x36] = {"ROL", .Zero_Page_X, rol}
    instruction_set[0x2e] = {"ROL", .Absolute, rol}
    instruction_set[0x3e] = {"ROL", .Absolute_X, rol}

    return instruction_set
}
