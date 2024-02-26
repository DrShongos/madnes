package console

import "mapper"

Mapper :: union {
    mapper.NROM,
}

mapper_read_memory :: proc(current_mapper: ^Mapper, addr: u16) -> u8 {
    #partial switch current in current_mapper {
    case mapper.NROM:
        return current.read_memory(&current, addr)
    }

    return 0
}

mapper_write_memory :: proc(current_mapper: ^Mapper, addr: u16, val: u8) {
    #partial switch current in current_mapper {
    case mapper.NROM:
        current.write_memory(&current, addr, val)
    }
}
