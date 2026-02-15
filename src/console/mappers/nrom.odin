package mappers

import "../../formats"

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

    nrom.prg_rom = make([]u8, nes2_file.prg_rom_size)
    copy(nrom.prg_rom[:], nes2_file.prg_rom)

    nrom.chr_rom = make([]u8, nes2_file.chr_rom_size)
    copy(nrom.chr_rom[:], nes2_file.chr_rom)

    nrom.nametable_mirroring = NROM_Nametable(nes2_file.nametable_layout)
    nrom.prg_ram = make([]u8, nes2_file.prg_ram_size)

    return nrom
}

nrom_remove :: proc(nrom: ^NROM) {
    delete(nrom.prg_rom)
    delete(nrom.chr_rom)
    delete(nrom.prg_ram)
}

// Reads memory from the NROM cartridge, based on the specified address banks.
// Alongside the byte, returns a bool that specifies whether the read operation had succeeded.
nrom_mem_read :: proc(nrom: ^NROM, address: u16) -> (bool, u8) {
    // (0x6000 - 0x7fff) - PRG Ram, Mirrored
    if address >= 0x6000 && address <= 0x7fff {
        return true, nrom.prg_ram[(int(address) % len(nrom.prg_ram))]
    }

    // (0x8000 - 0xffff) - PRG Rom, Mirrored at half-way point or full depending on size.
    if address >= 0x8000 && address <= 0xffff {
        return true, nrom.prg_rom[(int(address) % len(nrom.prg_rom))]
    }

    // (0x0000 - 0x1fff) - CHR Rom
    //if address >= 0x0000 && address <= 0x1fff {
    //    return true, nrom.chr_rom[(int(address) % len(nrom.chr_rom))]
    //}

    return false, 0
}

// Writes memory to the NROM cartridge, based on the specified address banks.
// Returns a bool that specifies whether the write operation had succeeded.
nrom_mem_write :: proc(nrom: ^NROM, address: u16, value: u8) -> bool {
    if address >= 0x6000 && address <= 0x7fff {
        nrom.prg_ram[(int(address) % len(nrom.prg_ram))] = value
        return true
    }

    // ROM data isn't supposed to be writable.
    // Simply returns true to discard further write operation.
    if address >= 0x8000 && address <= 0xffff {
        return true
    }

    return false
}

