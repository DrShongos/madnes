package console

RGB_Color :: struct {
    r: u8,
    g: u8,
    b: u8,
}

/// The system palette stores all the colours a NES program
/// Could use for it's rendering.
/// The palette contains 64 entries, each stored in an RGB888 format.
System_Palette :: struct {
    entries: [64]RGB_Color,
}

System_Palette_File_Error :: enum {
    Ok,
    Not_Found,
    Out_Of_Memory,
}

//read_palette_from_path :: proc(path: string) -> System_Palette {
//    palette_file = 
//}

//read_palette_from_data :: proc(data: []u8) -> System_Palette {
//
//}
