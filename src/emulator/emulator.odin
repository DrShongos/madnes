package emulator

import "../console"
import "../formats"

import "core:fmt"
import "core:os"

import rl "vendor:raylib"


Emulator :: struct {
    emulated_console: console.Console,
    ppu_texture: rl.Texture2D,
}

@(private)
prepare_ppu_texture :: proc(emulator: ^Emulator) {
    base_image := rl.GenImageColor(console.PPU_FRAME_WIDTH, console.PPU_FRAME_HEIGHT, rl.BLACK)
    defer rl.UnloadImage(base_image)

    emulator.ppu_texture = rl.LoadTextureFromImage(base_image)
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

    rl.InitWindow(console.PPU_FRAME_WIDTH * 4, console.PPU_FRAME_HEIGHT * 4, "MADNES")
    prepare_ppu_texture(&emulator)

    return emulator
}

emulator_run :: proc(emulator: ^Emulator) {
    main_loop: for {
        if (rl.WindowShouldClose()) { 
            break
        }

        console.console_tick(&emulator.emulated_console)

        emulator_render(emulator)

    }
}

// A debug function that renders all the tiles within the specified pattern table
emulator_pattern_table_dump :: proc(emulator: ^Emulator, pattern_table: u16) {
    for pattern_index in 0 ..= 0xff {
        x := pattern_index % 0x10
        y := pattern_index >> 4
        console.ppu_render_tile(
            &emulator.emulated_console.ppu,
            &emulator.emulated_console.mapper,
            pattern_index,
            pattern_table * 0x1000,
            8 * x,
            8 * y,
        )
    }
}

emulator_render :: proc(emulator: ^Emulator) {
    if emulator.emulated_console.ppu.scanline == 241 {
        console.ppu_render_nametable(&emulator.emulated_console.ppu, &emulator.emulated_console.mapper)
        rl.UpdateTexture(emulator.ppu_texture, raw_data(emulator.emulated_console.ppu.frame[:]))
    }

    rl.BeginDrawing()
    rl.DrawTextureEx(emulator.ppu_texture, {0.0, 0.0}, 0.0, 4.0, rl.WHITE)

    rl.ClearBackground(rl.BLACK)

    rl.EndDrawing()
}

emulator_delete :: proc(emulator: ^Emulator) {
    rl.UnloadTexture(emulator.ppu_texture)
    rl.CloseWindow()
    console.console_delete(&emulator.emulated_console)
}
