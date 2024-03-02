package console

nop_unofficial :: proc(
    cpu: ^CPU,
    console: ^Console,
    addressing_mode: Addressing_Mode,
) -> u8 {
    read_address(addressing_mode, cpu, console)

    cpu_fetch(cpu, console)
    return 2
}
