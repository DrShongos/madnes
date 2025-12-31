package console

Console :: struct {
    cpu: CPU,
}

console_new :: proc() -> Console {
    console := Console {
        cpu = cpu_new(),
    }

    return console
}

console_tick :: proc(console: ^Console) {
    cpu_tick(&console.cpu)
}
