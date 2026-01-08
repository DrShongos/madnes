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

    instruction_set[0xa2] = {"LDX", .Immediate, ldx}
    instruction_set[0xa6] = {"LDX", .Zero_Page, ldx}
    instruction_set[0xb6] = {"LDX", .Zero_Page_Y, ldx}
    instruction_set[0xae] = {"LDX", .Absolute, ldx}
    instruction_set[0xbe] = {"LDX", .Absolute_Y, ldx}

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

    instruction_set[0x85] = {"STA", .Zero_Page, sta}
    instruction_set[0x95] = {"STA", .Zero_Page_X, sta}
    instruction_set[0x8d] = {"STA", .Absolute, sta}
    instruction_set[0x9d] = {"STA", .Absolute_X, sta}
    instruction_set[0x99] = {"STA", .Absolute_Y, sta}
    instruction_set[0x81] = {"STA", .Indexed_Indirect, sta}
    instruction_set[0x91] = {"STA", .Indirect_Indexed, sta}

    instruction_set[0x20] = {"JSR", .Absolute, jsr}
    instruction_set[0x60] = {"RTS", .Implied, rts}

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

    return instruction_set
}
