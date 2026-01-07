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

    instruction_set[0x86] = {"STX", .Zero_Page, stx}
    instruction_set[0x96] = {"STX", .Zero_Page_Y, stx}
    instruction_set[0x8E] = {"STX", .Absolute, stx}

    return instruction_set
}
