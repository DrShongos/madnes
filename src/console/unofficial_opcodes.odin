package console

nop_unofficial :: proc(cpu: ^CPU, addressing_mode: Addressing_Mode) -> u8 {
    read_address(addressing_mode, cpu)

    cpu_fetch(cpu)
    return 2
}
