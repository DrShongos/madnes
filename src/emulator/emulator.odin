package emulator

import "../console"
import "../console/mapper"
import "core:fmt"
import "vendor:sdl2"

Emulator :: struct {
    window:       ^sdl2.Window,
    // Will be replaced with an OpenGL Renderer
    sdl_renderer: ^sdl2.Renderer,
    console:      console.Console,
    running:      bool,
}

init_emulator :: proc() -> Emulator {
    sdl2.Init({.VIDEO, .EVENTS, .AUDIO})
    emulator := Emulator{}
    emulator.window = sdl2.CreateWindow("madnes", 0, 0, 1065, 720, {})
    emulator.sdl_renderer = sdl2.CreateRenderer(
        emulator.window,
        0,
        {.SOFTWARE},
    )
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

        sdl2.RenderClear(emulator.sdl_renderer)

        sdl2.RenderPresent(emulator.sdl_renderer)
    }
}
