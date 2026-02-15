package console

PPU_SPRITE_OVERFLOW :: 0x20
PPU_SPRITE_ZERO :: 0x40
PPU_VBLANK :: 0x80
PPU_BUS_BITS :: 0x1f

PPU :: struct {
    status:      u8,
    initialized: bool,
}

ppu_new :: proc() -> PPU {
    ppu := PPU {
        initialized = false,
        status      = 0,
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

ppu_mem_read :: proc(ppu: ^PPU, address: u16) -> (bool, u8) {
    if address == 0x2002 {
        return true, ppu.status
    }

    return false, 0
}

ppu_mem_write :: proc(ppu: ^PPU, address: u16, val: u8) -> bool {
    if address == 0x2002 {
        // PPUSTATUS is unwritable, return.
        return true
    }

    return false
}

ppu_tick :: proc(ppu: ^PPU) {

}

