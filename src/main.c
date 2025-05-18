#include <raylib.h>
#include <stdio.h>

#include "emu/console.h"
#include "emu/cpu.h"

int main(int argc, char **argv)
{
    struct console console;
    processor_reset(&console.cpu);

    if (argc < 2) {
        printf("ERROR: ROM not specified. Terminating.\n");
        return -1;
    }

    int load_result = console_load_test_rom(&console, argv[1]);
    if (load_result != 0) {
        printf("ERROR: Failed to open ROM file. Terminating.\n");
        return -1;
    }
    printf("%d %d\n", console.cpu.internal_memory[0x8000],
           console.cpu.internal_memory[0xC000]);

    return 0;
}
