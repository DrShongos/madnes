package mapper

import "core:slice"
import "core:fmt"

NROM :: struct {
    using mapper_interface: Mapper_Interface(NROM),

    prg_rom: []u8,
    prg_ram: [8092]u8,

    chr_rom: [0x2000]u8,
}

init_nrom :: proc(prg_rom: []u8, chr_rom: []u8) -> NROM {
    nrom := NROM{}
    nrom.prg_rom = make([]u8, len(prg_rom))
 
    copy(nrom.prg_rom, prg_rom[:]) 

    if chr_rom != nil {
        copy(nrom.chr_rom[:], chr_rom)
    }

    nrom.read_memory = nrom_read_memory 
    nrom.write_memory = nrom_write_memory

    return nrom
}
 
//@(private)
nrom_read_memory :: proc(self: ^NROM, addr: u16) -> u8 {
    if addr >= 0x6000 && addr <= 0x7fff {
        prg_addr := addr - u16(len(self.prg_rom))
        return self.prg_ram[addr % u16(len(self.prg_ram))]
    }

    if addr >= 0x8000 && addr <= 0xFFFF {
        prg_addr := addr % u16(len(self.prg_rom))
        return self.prg_rom[addr % u16(len(self.prg_rom))]
    }

    return 0 // TODO
}

//@(private)
nrom_write_memory :: proc(self: ^NROM, addr: u16, val: u8) {
    if addr >= 0x6000 && addr <= 0x7fff {
        self.prg_ram[addr % u16(len(self.prg_ram))] = val
    }
}
