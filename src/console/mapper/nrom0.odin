package mapper

NROM0 :: struct {
    using mapper_interface: Mapper_Interface(NROM0),

    prg_rom: [dynamic]u8,
    prg_ram: [0x8000]u8,

    chr_rom: [0x2000]u8,
}

 
read_memory :: proc(self: ^NROM0, addr: u16) -> u8 {
    return 0 // TODO
}

write_memory :: proc(self: ^NROM0, addr: u16) {

}
