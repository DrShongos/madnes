package rom_formats

import "../console"

// TODO: More ROM Formats
ROM_Format :: union {
    INES_Format,
}

Target_Format :: enum {
    INES,
}

ROM_Error :: enum {
    Unknown_Format,
    Unknown_Mapper,
    None,
}

Loading_Error :: union {
    ROM_Error,
    INES_Parse_Error,
}

load_rom :: proc(data: []byte, target_format: Target_Format) -> (ROM_Format, Loading_Error) {
    switch target_format {
    case .INES: 
        return parse_ines_file(data)
    }

    return nil, ROM_Error.Unknown_Format 
}

error_occured :: proc(error: Loading_Error) -> bool {
    switch err in error {
    case ROM_Error:
       if err == .None {
           return false
       }
       return true
    case INES_Parse_Error:
        if err == .None {
            return false
        }
        return true
    }

    return true // unreachable
}

load_to_console :: proc(emulated_console: ^console.Console, format: ^ROM_Format) {
    switch rom in format {
    case INES_Format:
        console.load_prg_rom(emulated_console, rom.prg_rom)
    }
}

init_mapper :: proc(rom_format: ^ROM_Format) -> (console.Mapper, Loading_Error) {
    switch format in rom_format {
        case INES_Format:
            return ines_init_mapper(&format)
    }

    return nil, ROM_Error.Unknown_Format
}
