package console

import "core:fmt"
import "mappers"

PPU_VRAM_SIZE :: 0x2000

// PPU STATUS BITS
PPU_SPRITE_OVERFLOW :: 0x20
PPU_SPRITE_ZERO :: 0x40
PPU_VBLANK :: 0x80
PPU_BUS_BITS :: 0x1f

// PPU FRAME INFO
PPU_FRAME_WIDTH :: 256
PPU_FRAME_HEIGHT :: 240

PPU_NAMETABLE_SIZE :: 0x3c0

NAMETABLE_0 :: 0x2000
NAMETABLE_1 :: 0x2400
NAMETABLE_2 :: 0x2800
NAMETABLE_3 :: 0x2C00

PPU_Ctrl_Flag :: enum {
    // Toggled at the end of the NMI interrupt
    VBlank_NMI_Output                = 7,
    // Specifies the behaviour of the EXT pins
    // (0 - Read backdrop, 1 - Color output)
    Master_Select                    = 6,
    // (0 - 8x8 pixels, 1 - 8x16)
    Sprite_Size                      = 5,

    // (0 - 0x0000, 1 - 0x1000)
    Background_Pattern_Table_Address = 4,
    // (0 - 0x0000, 1- 0x1000), Ignored if using 8x16 sprites.
    Sprite_Pattern_Table_Address     = 3,
    // Address increment during CPU read of the PPU data
    // (0 - Increment by 1, 1 - Increment by 32)
    VRAM_Increment                   = 2,

    // The base nametable address is stored in two bits
    // (0 - 0x2000, 1 - 0x2400, 2 - 0x2800, 3 - 0x2c00)
    // These can be used to specify the scroll position.
    Base_Nametable_Address_Bit_2     = 1,
    Base_Nametable_Address_Bit_1     = 0,
}

PPU_Ctrl :: bit_set[PPU_Ctrl_Flag]

PPU_Mask_Flag :: enum {
    Emphasize_Blue      = 7,
    Emphasize_Green     = 6,
    Emphasize_Red       = 5,
    Render_Sprites      = 4,
    Render_Background   = 3,
    // Specifies whether the PPU should render sprites in the 8th leftmost pixels
    // (0 - Don't render, 1 - Render)
    Sprite_Overscan     = 2,
    // Specifies whether the PPU should render the background in the 8th leftmost pixels
    // (0 - Don't render, 1 - Render)
    Background_Overscan = 1,
    // Specifies whether the PPU should render in Greyscale or use colors
    // (0 - Render with color, 1 - Greyscale)
    Use_Greyscale       = 0,
}

PPU_Mask :: bit_set[PPU_Mask_Flag]

// A wrapper struct for PPU registers that accept two bytes as a value.
// Usually used to produce a 16-bit address.
// Do not modify it's data outside of the `double_write_send()` proc
// Controlled by the PPU's write latch.
Double_Write :: struct {
    first_byte:  u8,
    second_byte: u8,
}

PPU :: struct {
    // The PPUSTATUS is used to track current rendering events.
    status:           u8,
    ctrl:             PPU_Ctrl,

    // The PPUMASK register contains flags that specify what assets should
    // be rendered by the PPU.
    mask:             PPU_Mask,

    // The direct address of an OAM Sprite.
    // Most games use the OAMDMA instead.
    oamaddr:          u8,

    // Used to write sprite data into the OAM.
    // Writing into OAMDATA inserts the data at the current OAMADDR
    // and then increments it.
    oamdata:          u8,
    vram:             [PPU_VRAM_SIZE]u8,
    // Used by the CPU as a pointer to the data on VRAM.
    // It is a 16-bit value, which can only be modified by writing
    // Two different bytes individually.
    vram_address:     Double_Write,

    // The PPUDATA register during reading returns data previously held in the buffer.
    // After being accessed, the buffer gets updated to hold the next value.
    vram_data_buffer: u8,

    ////////////// INTERNAL REGISTERS ////////////////////////////

    // Controls whether the PPUSCROLL and PPUADDR register writes are
    // being sent to the first or second byte.
    // (false - first, true - second)
    write_latch:      bool,
    initialized:      bool,

    // The image produced by the PPU
    frame:            [PPU_FRAME_WIDTH * PPU_FRAME_HEIGHT]u32,
}

ppu_new :: proc() -> PPU {
    ppu := PPU {
        status      = 0,
        write_latch = false,
        initialized = false,
    }

    for i in 0 ..< PPU_VRAM_SIZE {
        ppu.vram[i] = 0
    }

    return ppu
}

ppu_init :: proc(ppu: ^PPU) {
    if ppu.initialized {
        return
    }

    ppu.initialized = true
    ppu.status |= PPU_VBLANK
    ppu.status |= PPU_SPRITE_OVERFLOW
}

// Sends a byte to a double write register, checking whether it is a first or
// a second write
double_write_send :: proc(ppu: ^PPU, reg: ^Double_Write, val: u8) {
    if !ppu.write_latch {
        reg.first_byte = val
        ppu.write_latch = true
    } else {
        reg.second_byte = val
        ppu.write_latch = false
    }
}

// Returns the value of a double write register as an unsigned 16-bit value.
double_write_as_u16 :: proc(val: Double_Write) -> u16 {
    first := u16(val.first_byte)
    second := u16(val.second_byte)
    word: u16 = u16(second | (first << 8))

    return word
}

u16_to_double_write :: proc(address: u16) -> Double_Write {
    second, first := address_to_bytes(address)

    return Double_Write{first_byte = first, second_byte = second}
}

set_bit :: proc(bitset: u8, flag: u8) -> u8 {
    return bitset | flag
}

clear_bit :: proc(bitset: u8, flag: u8) -> u8 {
    return bitset & (~flag)
}

@(private)
ppuaddr_increment :: proc(ppu: ^PPU) {
    vram_u16 := double_write_as_u16(ppu.vram_address)

    if .VRAM_Increment in ppu.ctrl {
        ppu.vram_address = u16_to_double_write(vram_u16 + 32)
    } else {
        ppu.vram_address = u16_to_double_write(vram_u16 + 1)
    }
}

@(private)
nametable_mirror :: proc(mapper: ^mappers.NROM, address: u16) -> u16 {
    if mapper.nametable_mirroring == .Horizontal {
        if address >= NAMETABLE_2 {
            return address - 0x0800
        }

        return address
    }

    if (address >= NAMETABLE_1 && address <= NAMETABLE_2) ||
       (address >= NAMETABLE_3) {
        return address - 0x0400
    }

    return address
}

// A wrapper function to fetch CHR memory from all the console's components
@(private)
ppu_vram_read :: proc(ppu: ^PPU, mapper: ^mappers.NROM, address: u16) -> u8 {
    mapper_accessed, mapper_byte := mappers.nrom_ppu_read(mapper, address)
    if mapper_accessed {
        return mapper_byte
    }

    if address >= 0x2000 && address <= 0x2fff {
        nametable_address := nametable_mirror(mapper, address)
        return ppu.vram[nametable_address % PPU_VRAM_SIZE]
    }

    // TODO: (0x3f00-0x3fff) SHOULD BE CONFIGURED TO RETURN DATA FROM THE PALETTE TABLE
    return ppu.vram[address % PPU_VRAM_SIZE]
}

// A wrapper function to write CHR memory into all the console's components
@(private)
ppu_vram_write :: proc(
    ppu: ^PPU,
    mapper: ^mappers.NROM,
    address: u16,
    val: u8,
) {
    // TODO: Configure to handle mappers (once a mapper with CHR-RAM gets implemented)
    // And exclude the palette table
    if address >= 0x2000 && address <= 0x2fff {
        nametable_address := nametable_mirror(mapper, address)
        ppu.vram[nametable_address % PPU_VRAM_SIZE] = val
    }
    ppu.vram[address % PPU_VRAM_SIZE] = val
}

ppu_mem_read :: proc(
    ppu: ^PPU,
    mapper: ^mappers.NROM,
    address: u16,
) -> (
    bool,
    u8,
) {
    if address == 0x2002 {
        ppu_status := ppu.status
        // After the register is read, the VBlanking flag is set to 0
        //ppu.status = clear_bit(ppu.status, PPU_VBLANK)

        return true, ppu_status
    }

    // OAMADDR is write-only
    if address == 0x2003 {
        return true, 0
    }

    if address == 0x2004 {
        return true, ppu.oamdata
    }

    // PPUADDR is write-only
    if address == 0x2006 {
        return true, 0
    }

    if address == 0x2007 {
        current_buf := ppu.vram_data_buffer
        ppu.vram_data_buffer = ppu_vram_read(
            ppu,
            mapper,
            double_write_as_u16(ppu.vram_address),
        )
        ppuaddr_increment(ppu)

        return true, current_buf
    }

    return false, 0
}

ppu_mem_write :: proc(
    ppu: ^PPU,
    mapper: ^mappers.NROM,
    address: u16,
    val: u8,
) -> bool {
    if address == 0x2002 {
        // PPUSTATUS is read-only, return.
        return true
    }

    if address == 0x2003 {
        ppu.oamaddr = val
        return true
    }

    if address == 0x2004 {
        ppu.oamdata = val
        ppu.oamaddr += 1
    }

    if address == 0x2006 {
        double_write_send(ppu, &ppu.vram_address, val)
        return true
    }

    if address == 0x2007 {
        ppu_vram_write(ppu, mapper, double_write_as_u16(ppu.vram_address), val)
        ppuaddr_increment(ppu)
        return true
    }

    return false
}

ppu_tick :: proc(ppu: ^PPU, mapper: ^mappers.NROM) {
    ppu_render_nametable(ppu, mapper)
}

// Gets the nametable address from the PPUCTRL flags
@(private)
get_nametable_base_address :: proc(ppu: ^PPU) -> u16 {
    nametable_address_flags: PPU_Ctrl = {
        .Base_Nametable_Address_Bit_2,
        .Base_Nametable_Address_Bit_1,
    }

    nametable_ctrl := transmute(u8)(ppu.ctrl & nametable_address_flags)

    if nametable_ctrl == 1 {
        return NAMETABLE_1
    }

    if nametable_ctrl == 2 {
        return NAMETABLE_2
    }

    if nametable_ctrl == 3 {
        return NAMETABLE_3
    }

    // Nametable Address bits are equal to 0
    return NAMETABLE_0
}

nametable_pattern_start :: proc(ppu: ^PPU) -> u16 {
    if .Background_Pattern_Table_Address in ppu.ctrl {
        return 0x1000
    }

    return 0x0000
}

ppu_render_nametable :: proc(ppu: ^PPU, mapper: ^mappers.NROM) {
    nametable_addr := get_nametable_base_address(ppu)

    nametable_end := nametable_addr + PPU_NAMETABLE_SIZE

    x: int = 0
    y: int = 0

    for nametable_entry in nametable_addr ..< nametable_end {
        // Nametables have 30 rows of 32 tiles
        tile_index := ppu_vram_read(ppu, mapper, nametable_entry)
        ppu_render_tile(
            ppu,
            mapper,
            int(tile_index),
            nametable_pattern_start(ppu),
            8 * x,
            8 * y,
        )

        x += 1
        if x % 32 == 0 {
            x = 0
            y += 1
        }
    }
}

ppu_render_tile :: proc(
    ppu: ^PPU,
    mapper: ^mappers.NROM,
    pattern_table_index: int,
    pattern_start: u16,
    x: int,
    y: int,
) {
    first_plane := pattern_start + u16(pattern_table_index * 16)
    second_plane := pattern_start + u16(pattern_table_index * 16) + 8

    color_index := 0

    y_start := y

    for pixel_offset in 0 ..< 8 {
        first_plane_layer := ppu_vram_read(
            ppu,
            mapper,
            first_plane + u16(pixel_offset),
        )
        second_plane_layer := ppu_vram_read(
            ppu,
            mapper,
            second_plane + u16(pixel_offset),
        )

        y := y_start + pixel_offset

        // Go through each bit of the current layers, while checking both planes
        // The test specifies the color in the following way:
        // Both bits in both planes set to 0: Background/Transparent
        // First plane set, second plane clear: Color 1,
        // First plane clear, second plane set: Color 2,
        // Both planes set: Color 3
        bit_test: u8 = 0x80

        x_start := x

        for x_offset in 0 ..< 8 {
            first_plane_test := first_plane_layer & bit_test
            second_plane_test := second_plane_layer & bit_test

            x := x_start + x_offset

            if first_plane_test != 0 && second_plane_test == 0 {
                ppu_frame_set_pixel(ppu, x, y, 0xff, 0, 0)
            }

            if first_plane_test == 0 && second_plane_test != 0 {
                ppu_frame_set_pixel(ppu, x, y, 0, 0xff, 0)
            }

            if first_plane_test != 0 && second_plane_test != 0 {
                ppu_frame_set_pixel(ppu, x, y, 0, 0, 0xff)
            }

            if first_plane_test == 0 && second_plane_test == 0 {
            }

            bit_test /= 2

        }
    }
}

ppu_frame_set_pixel :: proc(ppu: ^PPU, x: int, y: int, r: u8, g: u8, b: u8) {
    pixel_coords := (y * PPU_FRAME_WIDTH) + x

    // Pixel data is stored in a RGBA32 format.
    ppu.frame[pixel_coords] |= u32(r)
    ppu.frame[pixel_coords] |= u32(g) << 8
    ppu.frame[pixel_coords] |= u32(b) << 16

    // Add a filled alpha channel at the start
    ppu.frame[pixel_coords] |= 0xff << 24
}
