package mapper

Mapper_Interface :: struct($T: typeid) {
    read_memory: proc(self: ^T, addr: u16) -> u8,
    write_memory: proc(self: ^T, addr: u16),
}
