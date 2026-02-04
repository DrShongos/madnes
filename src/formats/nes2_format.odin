package formats

import "core:fmt"
import "core:os"
MAPPER_NUMBERS_BITS: u8 : 0xf0
CONSOLE_TYPE_BITS: u8 : 0x03
CPU_TIMING_BITS: u8 : 0x02

Nametable_Layout :: enum {
    Vertical   = 0,
    Horizontal = 1,
}

Console_Type :: enum {
    NES        = 0,
    Vs_System  = 1,
    Playchoice = 2,
    Other      = 3,
}

CPU_Timing :: enum {
    NTSC         = 0,
    PAL          = 1,
    Multi_Region = 2,
    Dendy        = 3,
}


NES2_0_Format :: struct {
    // Header Info
    trainer_data:         [512]u8,
    prg_rom_size:         u16,
    chr_rom_size:         u16,
    mapper:               u16,

    // Nametable config
    nametable_layout:     Nametable_Layout,
    use_battery:          bool,
    use_trainer:          bool,
    alt_nametables:       bool,

    // Specifies what console was the cartridge producer for.
    console_type:         Console_Type,
    submapper:            u8,
    prg_ram_size:         u16,
    prg_battery_ram_size: u16,
    chr_ram_size:         u16,
    chr_battery_ram_size: u16,
    cpu_timing:           CPU_Timing,

    // Data
    prg_rom:              []u8,
    chr_rom:              []u8,
}

@(private)
parse_size_lsbs :: proc(format: ^NES2_0_Format, data: []u8) {
    format.prg_rom_size |= u16(data[4])
    format.chr_rom_size |= u16(data[5])
}

@(private)
parse_nametable_layout :: proc(format: ^NES2_0_Format, data: []u8) {
    format.nametable_layout = Nametable_Layout(data[6] & 0x01)
    format.use_battery = bool(data[6] & 0x02)
    format.use_trainer = bool(data[6] & 0x04)
    format.alt_nametables = bool(data[6] & 0x08)

    format.mapper |= u16((data[6] & 0xf0) >> 8)
}

@(private)
parse_console_type :: proc(format: ^NES2_0_Format, data: []u8) {
    format.console_type = Console_Type(data[7] & 0x03)
    format.mapper |= u16((data[7] & 0xf0) >> 4)
}

@(private)
parse_mapper_number :: proc(format: ^NES2_0_Format, data: []u8) {
    format.mapper |= (u16(data[8]) << 8) & 0x0f00
    format.submapper = data[8] >> 4
}

@(private)
parse_rom_msbs :: proc(format: ^NES2_0_Format, data: []u8) {
    format.chr_rom_size |= u16(data[9] & 0xf0) << 8
    format.prg_rom_size |= u16(data[9] & 0x0f) << 8
}

@(private)
parse_prg_ram :: proc(format: ^NES2_0_Format, data: []u8) {
    prg_ram_shift := data[10] & 0x0f
    prg_ram_battery_shift := data[10] & 0xf0

    format.prg_ram_size = 64 << prg_ram_shift
    if prg_ram_shift == 0 {
        format.prg_ram_size = 0
    }

    format.prg_battery_ram_size = 64 << prg_ram_battery_shift
    if prg_ram_battery_shift == 0 {
        format.prg_battery_ram_size = 0
    }
}

@(private)
parse_chr_ram :: proc(format: ^NES2_0_Format, data: []u8) {
    chr_ram_shift := data[11] & 0x0f
    chr_ram_battery_shift := data[11] & 0xf0

    format.chr_ram_size = 64 << chr_ram_shift
    if chr_ram_shift == 0 {
        format.chr_ram_size = 0
    }

    format.chr_battery_ram_size = 64 << chr_ram_battery_shift
    if chr_ram_battery_shift == 0 {
        format.chr_battery_ram_size = 0
    }
}

@(private)
parse_timing :: proc(format: ^NES2_0_Format, data: []u8) {
    timing_flag := data[12] & 0x02
    format.cpu_timing = CPU_Timing(timing_flag)
}

@(private)
parse_header :: proc(format: ^NES2_0_Format, data: []u8) {
    // Byte 4 and 5 represent the Least Significant Bytes of PRG and CHR Rom sizes, respectively.
    parse_size_lsbs(format, data)

    // Byte 6 contains the the first 4 bits of the LSB of the mapper number and the nametable data.
    parse_nametable_layout(format, data)

    // Byte 7 contains the remaining bits of the LSB of the mapper number, as well as the console type.
    parse_console_type(format, data)

    // Byte 8 contains the last bits of the mapper number alongside the submapper number.
    parse_mapper_number(format, data)

    // Byte 9 - CHR-ROM & PRG-ROM SIZE MSB
    parse_rom_msbs(format, data)

    // Byte 10 - PRG (battery) RAM sizes
    parse_prg_ram(format, data)

    // Byte 11 - CHR (battery) RAM sizes
    parse_chr_ram(format, data)

    // Byte 12 - Timing modes
    parse_timing(format, data)

    // TODO: Implement all the other header info
}

@(private)
load_rom_data :: proc(format: ^NES2_0_Format, data: []u8) {
    // Skip the header
    offset := 16

    // Some modified games implemented additional CPU code for compatibility between hardware.
    // If present, the code is always 512 bytes in size.
    if (format.use_trainer) {
        copy(format.trainer_data[:], data[offset:(offset + 512)])
    }
    offset += 512

    // PRG ROM
    prg_rom, prg_alloc_err := make_slice([]u8, format.prg_rom_size)
    if prg_alloc_err != .None {
        fmt.eprintf(
            "NES2.0: Failed to allocate PRG ROM data: %s",
            prg_alloc_err,
        )
        os.exit(-1)
    }

    format.prg_rom = prg_rom
    prg_rom_end := offset + int(format.prg_rom_size)
    copy(format.prg_rom, data[offset:prg_rom_end])

    offset = prg_rom_end

    // CHR ROM
    chr_rom, chr_alloc_err := make_slice([]u8, format.chr_rom_size)
    if chr_alloc_err != .None {
        fmt.eprintf(
            "NES2.0: Failed to allocate CHR ROM data: %s",
            chr_alloc_err,
        )
        os.exit(-1)
    }

    format.chr_rom = chr_rom
    chr_rom_end := offset + int(format.chr_rom_size)
    copy(format.chr_rom, data[offset:chr_rom_end])

    offset = chr_rom_end
}

nes2_0_parse :: proc(data: []u8) -> NES2_0_Format {
    rom_file: NES2_0_Format

    parse_header(&rom_file, data)
    load_rom_data(&rom_file, data)

    return rom_file
}
