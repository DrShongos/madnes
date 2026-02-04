package mappers

import "../../formats"
import "core:fmt"
import "core:os"

NROM_Nametable :: enum {
    Vertical   = 0,
    Horizontal = 1,
}

NROM :: struct {
    prg_rom:             [0x10000]u8,
    prg_rom_mirror:      bool,
    chr_rom:             [0x2000]u8,
    chr_rom_mirror:      bool,
    nametable_mirroring: NROM_Nametable,
    prg_ram:             []u8,
}

nrom_from_nes2 :: proc(nes2_file: ^formats.NES2_0_Format) -> NROM {
    nrom: NROM

    copy(nrom.prg_rom[:], nes2_file.prg_rom)
    if int(nes2_file.prg_rom_size) < 0x10000 {
        nrom.prg_rom_mirror = true
    }

    copy(nrom.chr_rom[:], nes2_file.chr_rom)
    if nes2_file.chr_rom_size < 0x2000 {
        nrom.chr_rom_mirror = true
    }

    nrom.nametable_mirroring = NROM_Nametable(nes2_file.nametable_layout)
    prg_ram, prg_alloc_err := make_slice([]u8, nes2_file.prg_ram_size)
    if prg_alloc_err != .None {
        fmt.eprintf("NROM PRG_Ram alloc err: %s\n", prg_alloc_err)
        os.exit(-1)
    }

    return nrom
}

nrom_remove :: proc(nrom: ^NROM) {
    delete(nrom.prg_ram)
}

nrom_mem_read :: proc(nrom: ^NROM, address: u16) -> u8 {

}

nrom_mem_write :: proc(nrom: ^NROM, address: u16) {

}
