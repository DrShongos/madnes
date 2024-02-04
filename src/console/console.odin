package console

import "core:fmt"
import "core:os"

Console :: struct {
	cpu: CPU,
}

init_console :: proc() -> Console {
	console := Console{}
	console.cpu = init_cpu()

	return console
}

run_console :: proc(console: ^Console) {
	for {
		run_cycle(&console.cpu)
		if console.cpu.cycle == 255 {
			os.exit(-1)
		}
	}
}

load_prg_rom :: proc(console: ^Console, prg: []u8) {
	// The PRG ROM is loaded twice until mappers will be implemented
	copy(console.cpu.memory[PRG_ROM_START:], prg)
	copy(console.cpu.memory[PRG_ROM_MIRROR:], prg)
}


u16_to_u8 :: proc(word: u16) -> (u8, u8) {
	hi := (word & 0xFF)
	lo := word >> 8

	return u8(hi), u8(lo)
}

u8_to_u16 :: proc(hi: u8, lo: u8) -> u16 {
	hi := u16(hi)
	lo := u16(lo)
	word: u16 = u16(hi | (lo << 8))
	return word
}
