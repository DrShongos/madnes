package console

INSTRUCTION_SET_SIZE :: 0x100

Instruction_Code :: #type proc(cpu: ^CPU) -> u8

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
    action:          Instruction_Code,
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

    instruction_set[0x4c] = {"JMP", .Absolute, jmp_absolute}

    instruction_set[0xa2] = {"LDX", .Immediate, ldx_immediate}
    instruction_set[0xa6] = {"LDX", .Zero_Page, ldx_zero_page}
    instruction_set[0xb6] = {"LDX", .Zero_Page_Y, ldx_zero_page_y}
    instruction_set[0xae] = {"LDX", .Absolute, ldx_absolute}
    instruction_set[0xbe] = {"LDX", .Absolute_Y, ldx_absolute_y}

    return instruction_set
}
