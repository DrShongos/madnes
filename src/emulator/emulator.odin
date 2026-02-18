package emulator

import "../console"
import "../formats"

import "core:fmt"
import "core:os"

import sdl "vendor:sdl3"

Emulator :: struct {
    window:           ^sdl.Window,
    renderer:         ^sdl.Renderer,
    emulated_console: console.Console,
}

@(private)
setup_window :: proc(emulator: ^Emulator) {
    init_success := sdl.Init({.VIDEO, .EVENTS})
    if !init_success {
        fmt.eprintf("Failed to initialize SDL3: %s", sdl.GetError())
        os.exit(-1)
    }

    emulator.window = sdl.CreateWindow("MADNES", 1280, 720, {})
    if emulator.window == nil {
        fmt.eprintf("Failed to create the Window: %s", sdl.GetError())
        os.exit(-1)
    }

    emulator.renderer = sdl.CreateRenderer(emulator.window, "")
    if emulator.renderer == nil {
        fmt.eprintf("Failed to create the Renderer: %s", sdl.GetError())
        os.exit(-1)
    }
}

emulator_new :: proc(filepath: string) -> Emulator {
    rom_file, success := os.read_entire_file_from_filename(filepath)
    defer delete(rom_file)

    if !success {
        fmt.eprintf("Failed to open the specified ROM file.\n")
        os.exit(-1)
    }

    emulator := Emulator{}

    emulator.emulated_console = console.console_new()

    ines_format := formats.nes2_0_parse(rom_file)
    console.console_load_cartridge(&emulator.emulated_console, &ines_format)

    setup_window(&emulator)

    return emulator
}

emulator_run :: proc(emulator: ^Emulator) {
    main_loop: for {
        emu_event: sdl.Event
        for sdl.PollEvent(&emu_event) {
            #partial switch emu_event.type {
            case .QUIT:
                break main_loop
            }
        }

        console.console_tick(&emulator.emulated_console)

        sdl.RenderPresent(emulator.renderer)
    }
}

emulator_delete :: proc(emulator: ^Emulator) {
    console.console_delete(&emulator.emulated_console)
    sdl.DestroyRenderer(emulator.renderer)
    sdl.DestroyWindow(emulator.window)
    sdl.Quit()
}
