package console

Console :: struct {
    cpu: CPU,
}

console_new :: proc() -> Console {
    console := Console{}

    return console
}

console_tick :: proc(console: ^Console) {}
