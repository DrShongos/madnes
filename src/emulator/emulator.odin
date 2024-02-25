package emulator

import "../console"
import "vendor:sdl2"

Emulator :: struct {
    window:  ^sdl2.Window,
    console: console.Console,
    running: bool,
}

init_emulator :: proc() -> Emulator {
    sdl2.Init({.VIDEO, .EVENTS, .AUDIO})
    emulator := Emulator{}
    emulator.window = sdl2.CreateWindow("madnes", 0, 0, 1280, 720, {})
    emulator.console = console.init_console()
    emulator.running = true

    return emulator
}

run_emulator :: proc(emulator: ^Emulator) {
    for emulator.running {
        sdl_event: sdl2.Event
        for sdl2.PollEvent(&sdl_event) {
            #partial switch sdl_event.type {
            case .QUIT:
                emulator.running = false
            }
        }
        console.console_tick(&emulator.console)
    }
}
