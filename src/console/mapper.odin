package console

import "mapper"
import "core:fmt"

Mapper :: union {
    mapper.NROM,
}

// These two wrapper functions exist because accessing mapper memory via the .? keyword causes the mapper to decay into `nil` after a few instructions.

mapper_read_memory :: proc(current_mapper: ^Mapper, addr: u16) -> u8 {

    //fmt.println("Requested Mapper Memory read")
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
