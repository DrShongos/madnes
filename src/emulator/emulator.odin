package emulator

import "../console"
import "../formats"

import "core:fmt"
import "core:os"

import sdl "vendor:sdl3"

Emulator :: struct {
    window:           ^sdl.Window,
    surface:          ^sdl.Surface,
    renderer:         ^sdl.Renderer,
    ppu_texture:      ^sdl.Texture,
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

    emulator.surface = sdl.GetWindowSurface(emulator.window)
    emulator.renderer = sdl.CreateSoftwareRenderer(emulator.surface)

    if emulator.renderer == nil {
        fmt.eprintf("Failed to create the Renderer: %s", sdl.GetError())
        os.exit(-1)
    }

    emulator.ppu_texture = sdl.CreateTexture(
        emulator.renderer,
        .RGBA32,
        .STREAMING,
        8,
        8,
    )
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

        emulator_render(emulator)

    }
}

emulator_render :: proc(emulator: ^Emulator) {
    sample_tile := console.ppu_render_tile(
        &emulator.emulated_console.ppu,
        &emulator.emulated_console.mapper,
        3,
        0x0000,
    )
    fmt.println(sample_tile)

    sdl.UpdateTexture(
        emulator.ppu_texture,
        nil,
        &sample_tile,
        8 * size_of(u32),
    )

    sdl.RenderClear(emulator.renderer)


    render_target := sdl.FRect {
        x = 0.0,
        y = 0.0,
        w = 24.0,
        h = 24.0,
    }
    sdl.RenderTexture(
        emulator.renderer,
        emulator.ppu_texture,
        nil,
        &render_target,
    )

    sdl.RenderPresent(emulator.renderer)
    sdl.UpdateWindowSurface(emulator.window)
}

emulator_delete :: proc(emulator: ^Emulator) {
    console.console_delete(&emulator.emulated_console)
    sdl.DestroyRenderer(emulator.renderer)
    sdl.DestroyWindow(emulator.window)
    sdl.Quit()
}
