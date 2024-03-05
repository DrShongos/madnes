package console

import "core:fmt"

System_Colors :: [64]u32 {
    0x626262,
    0x001fb2,
    0x2404c8,
    0x5200b2,
    0x730076,
    0x800024,
    0x730b00,
    0x522800,
    0x244400,
    0x005700,
    0x005c00,
    0x005324,
    0x003c76,
    0x000000,
    0x000000,
    0x000000,
    0xababab,
    0x0d57ff,
    0x4b30ff,
    0x8a13ff,
    0xbc08d6,
    0xd21269,
    0xc72e00,
    0x9d5400,
    0x607b00,
    0x209800,
    0x00a300,
    0x009942,
    0x007db4,
    0x000000,
    0x000000,
    0x000000,
    0xffffff,
    0x53aeff,
    0x9085ff,
    0xd365ff,
    0xff57ff,
    0xff5dcf,
    0xff7757,
    0xfa9e00,
    0xbdc700,
    0x7ae700,
    0x43f611,
    0x26ef7e,
    0x2cd5f6,
    0x4e4e4e,
    0x000000,
    0x000000,
    0xffffff,
    0xb6e1ff,
    0xced1ff,
    0xe9c3ff,
    0xffbcff,
    0xffbdf4,
    0xffc6c3,
    0xffd59a,
    0xe9e681,
    0xcef481,
    0xb6fb9a,
    0xa9fac3,
    0xa9f0f4,
    0xb8b8b8,
    0x000000,
    0x000000,
}

PPU_Control_Flag :: enum {
    NMI_Enable             = 7,
    PPU_Master_Slave       = 6,
    Sprite_Height          = 5,
    Background_Tile_Select = 4,
    Sprite_Tile_Select     = 3,
    Increment_Mode         = 2,
}

PPU_Control_Flags :: bit_set[PPU_Control_Flag;u8]

NAMETABLE_ADDRESS_OFFSET_BITS :: 0b00000011

PPU_Mask_Flag :: enum {
    Blue_Emphasis            = 7,
    Green_Emphasis           = 6,
    Red_Emphasis             = 5,
    Show_Sprites             = 4,
    Show_Background          = 3,
    Show_Leftmost_Sprites    = 2,
    Show_Leftmost_Background = 1,
    Greyscale                = 0,
}

PPU_Mask_Flags :: bit_set[PPU_Mask_Flag;u8]

PPU_Status_Flag :: enum {
    VBlank_Started  = 7,
    Sprite_Zero_Hit = 6,
    Sprite_Overflow = 5,
}

PPU_Status_Flags :: bit_set[PPU_Status_Flag;u8]

Double_Write :: struct {
    first:  u8,
    second: u8,
}

double_write_send :: proc(double_write: ^Double_Write, ppu: ^PPU, val: u8) {
    if !ppu.second_write {
        double_write.first = val
        ppu.second_write = true
    } else {
        double_write.second = val
        ppu.second_write = false
    }
}

// Returns Double_Write's values as an u16 value.
// NOTE: The value is not little endian
double_write_as_u16 :: proc(double_write: ^Double_Write) -> u16 {
    return (u16(double_write.first) << 8) | u16(double_write.second)
}

PPU :: struct {
    control:           PPU_Control_Flags,
    mask:              PPU_Mask_Flags,
    status:            PPU_Status_Flags,
    vram:              [0x4000]u8,
    oam:               [0xFF]u8,
    oam_addr:          u8,
    scroll:            Double_Write,
    ppuaddr:           Double_Write,

    // Used to track initialization on startup
    initialized:       bool,

    // Internal registers 
    second_write:      bool,
    current_vram_addr: u16,
}

init_ppu :: proc(ppu: ^PPU) {
    ppu.status += {.VBlank_Started, .Sprite_Overflow}
    ppu.initialized = true
}

ppu_read_registers :: proc(ppu: ^PPU, addr: u16) -> u8 {
    switch addr {
    case 0x2002:
        ppu.second_write = false
        return transmute(u8)ppu.status
    case 0x2004:
        return ppu.oam[ppu.oam_addr]
    case 0x2007:
        vram_data := ppu.vram[ppu.current_vram_addr]
        if .Increment_Mode in ppu.control {
            ppu_set_vram_addr(ppu, ppu.current_vram_addr + 32)
        } else {
            ppu_set_vram_addr(ppu, ppu.current_vram_addr + 1)
        }
        return vram_data
    }

    return 0
}

ppu_write_registers :: proc(ppu: ^PPU, console: ^Console, addr: u16, val: u8) {
    switch addr {
    case 0x2000:
        ppu.control = transmute(PPU_Control_Flags)val
    case 0x2001:
        ppu.mask = transmute(PPU_Mask_Flags)val
    case 0x2003:
        ppu.oam_addr = val
    case 0x2004:
        ppu.oam[ppu.oam_addr] = val
        ppu.oam_addr += 1
    case 0x2005:
        double_write_send(&ppu.scroll, ppu, val)
    case 0x2006:
        double_write_send(&ppu.ppuaddr, ppu, val)

        ppu_set_vram_addr(ppu, double_write_as_u16(&ppu.ppuaddr))
    case 0x2007:
        ppu.vram[ppu.current_vram_addr] = val
        if .Increment_Mode in ppu.control {
            ppu_set_vram_addr(ppu, ppu.current_vram_addr + 32)
        } else {
            ppu_set_vram_addr(ppu, ppu.current_vram_addr + 1)
        }
    case 0x4014:
        write_start := u8_to_u16(0x00, val)
        console.cpu.suspended = true

        oam_write_addr := write_start
        for {
            write_index := oam_write_addr - write_start
            index := u8(write_index)

            ppu.oam[index] = read_memory(&console.cpu, console, oam_write_addr)
            oam_write_addr += 1
            if write_index >= 0xFF {
                console.cpu.suspended = false
                break
            }
        }
    }
}

ppu_set_vram_addr :: proc(ppu: ^PPU, addr: u16) {
    ppu.current_vram_addr = addr

    // Mirror the address
    if ppu.current_vram_addr > 0x3FFF {
        ppu.current_vram_addr %= 0x3FFF
    }
}
