#include <raylib.h>
#include <stdio.h>

#include "emu/console.h"
#include "emu/cpu.h"

int main()
{
    struct console console;
    processor_reset(&console.cpu);

    InitWindow(1056, 720, "Madnes");

    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(BLACK);
        EndDrawing();
    }

    printf("Hello World!\n");
    return 0;
}
