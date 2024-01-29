package madnes;

CPU :: struct {
    status: u8,
    accumulator: u8,
    register_x: u8,
    register_y: u8,

    stack_top: u8,
    program_counter: u16,
}
