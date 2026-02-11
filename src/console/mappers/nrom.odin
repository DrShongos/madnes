package mappers

import "../../formats"
import "core:fmt"
import "core:os"

NROM_Nametable :: enum {
    Vertical   = 0,
    Horizontal = 1,
}

NROM :: struct {
    prg_rom:             []u8,
    chr_rom:             []u8,
    nametable_mirroring: NROM_Nametable,
    prg_ram:             []u8,
}

nrom_from_nes2 :: proc(nes2_file: ^formats.NES2_0_Format) -> NROM {
    nrom: NROM

    prg_rom, prg_rom_alloc_err := make_slice([]u8, nes2_file.prg_rom_size)
    if prg_rom_alloc_err != .None {
        fmt.eprintf("NROM PRG_Rom alloc err: %s\n", prg_rom_alloc_err)
        os.exit(-1)
    }
    copy(nrom.prg_rom[:], nes2_file.prg_rom)

    chr_rom, chr_rom_alloc_err := make_slice([]u8, nes2_file.chr_rom_size)
    if chr_rom_alloc_err != .None {
        fmt.eprintf("NROM CHR_Rom alloc err: %s\n", chr_rom_alloc_err)
        os.exit(-1)
    }
    copy(nrom.chr_rom[:], nes2_file.chr_rom)

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

// Reads memory from the NROM cartridge, based on the specified address banks.
// Alongside the byte, returns a bool that specifies whether the read operation had succeeded.
nrom_mem_read :: proc(nrom: ^NROM, address: u16) -> (bool, u8) {
    if address >= 0x6000 && address <= 0x7fff {
        return true, nrom.prg_ram[(int(address) % len(nrom.prg_ram))]
    }

    if address >= 0x8000 && address <= 0xffff {
        return true, nrom.prg_rom[(int(address) % len(nrom.prg_rom))]
    }

    return false, 0
}

// Writes memory to the NROM cartridge, based on the specified address banks.
// Returns a bool that specifies whether the write operation had succeeded.
nrom_mem_write :: proc(nrom: ^NROM, address: u16) -> bool {
    return false
}

