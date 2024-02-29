package rom_formats

import "core:mem"
import "core:fmt"

import "../console"
import "../console/mapper"

INES_FILE_HEADER :: [4]u8{0x4E, 0x45, 0x53, 0x1A}

INES_PRG_ROM_UNIT :: 16384
INES_CHR_ROM_UNIT :: 8192

INES_Parse_Error :: enum {
    None,
    Invalid_Header,
    Invalid_PRG_Size,
}

INES_Header :: struct {
    prg_units: u8,
    chr_units: u8,
    flags6:    Flags6,
    flags7:    Flags7,
    mapper:    u8,
}

INES_Format :: struct {
    header:  INES_Header,
    trainer: []u8,
    prg_rom: []u8,
    // CHR Rom isn't always present.
    // If it isn't, all CHR data will be written into CHR Ram at runtime instead
    chr_rom: []u8,
}

MAPPER_NYBBLE :: 0b11110000
NES2_FORMAT_CHECK :: 0b00011000

Flag6 :: enum {
    Mirroring             = 0,
    Use_Persistent_Memory = 1,
    Use_Trainer           = 2,
    Four_Screen_VRAM      = 3,
}

Flag7 :: enum {
    VS_Unisystem = 1,
    PlayChoice   = 2,
}

Flags6 :: bit_set[Flag6]
Flags7 :: bit_set[Flag7]

parse_ines_file :: proc(data: []u8) -> (INES_Format, INES_Parse_Error) {
    ines_format := INES_Format{}
    ines_header := INES_Header{}

    ines_file_header := INES_FILE_HEADER

    if mem.compare(data[:4], ines_file_header[:]) != 0 {
        return ines_format, .Invalid_Header
    }

    // PRG Rom is supposed to always have a size
    ines_header.prg_units = data[4]

    if ines_header.prg_units == 0 {
        return ines_format, .Invalid_PRG_Size
    }

    prg_size := INES_PRG_ROM_UNIT * int(ines_header.prg_units)
    ines_format.prg_rom = make([]u8, prg_size)

    ines_header.chr_units = data[5]
    chr_size := INES_CHR_ROM_UNIT * int(ines_header.chr_units)

    flags6 := data[6]
    ines_header.flags6 = transmute(Flags6)flags6

    flags7 := data[7]
    ines_header.flags7 = transmute(Flags7)flags7

    higher_mapper_nybble := flags7 & MAPPER_NYBBLE

    ines_header.mapper = higher_mapper_nybble | (flags6 >> 4)

    trainer_offset := 16
    ines_format.trainer = nil
    if .Use_Trainer in ines_header.flags6 {
        ines_format.trainer = make([]u8, 512)
        copy(ines_format.trainer, data[16:512])
        trainer_offset = 16 + 512
    }

    prg_offset := trainer_offset + prg_size
    copy(ines_format.prg_rom, data[trainer_offset:prg_offset])

    chr_offset := prg_offset + chr_size
    if chr_size == 0 {
        ines_format.chr_rom = nil
    } else {
        ines_format.chr_rom = make([]u8, chr_size)
        copy(ines_format.chr_rom, data[prg_offset:chr_offset])
    }

    ines_format.header = ines_header

    return ines_format, .None
}

delete_ines_file :: proc(file: ^INES_Format) {
    if file.trainer != nil {
        delete(file.trainer)
    }

    delete(file.prg_rom)

    if file.chr_rom != nil {
        delete(file.chr_rom)
    }
}

ines_init_mapper :: proc(
    ines_format: ^INES_Format,
) -> (
    console.Mapper,
    ROM_Error,
) {
    switch ines_format.header.mapper {
    case 0:
        return mapper.init_nrom(ines_format.prg_rom, ines_format.chr_rom), nil
    }

    return nil, .Unknown_Mapper
}
