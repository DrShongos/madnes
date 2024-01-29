package madnes

import "core:fmt"
import "core:os"

import "rom_formats"

main :: proc() {
	nestest_file, success := os.read_entire_file_from_filename("nestest.nes")
	if !success {
		fmt.printf("COULD NOT OPEN FILE\n")
		os.exit(-1)
	}

	test_rom, err := rom_formats.parse_ines_file(nestest_file)
	defer rom_formats.delete_ines_file(&test_rom)

	if err != .None {
		fmt.printf("An error occured while parsing an INES file \n")
		os.exit(-1)
	}
}

print_bytes :: proc(bytes: []byte) {
	for data in bytes {
		fmt.printf("%d ", data)
	}
	fmt.printf("\n")
}
