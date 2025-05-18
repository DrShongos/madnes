#include "cpu.h"
#include "console.h"

void processor_reset(struct processor *cpu)
{
    cpu->status_flags = PROCESSOR_DEFAULT_STATUS;
    cpu->cycle = 0;
    cpu->register_x = 0;
    cpu->register_y = 0;
    cpu->accumulator = 0;
    cpu->stack_top = STACK_TOP_START;

    cpu->program_counter = TEST_ROM_START;

    // TODO: The real 6502 is filled with random values at start. This is used
    // by multiple NES games for Random Number Generation. Add an ability to
    // configure that.
    for (u16 i = 0; i < CPU_MEM_MAX_INDEX; i += 1)
        cpu->internal_memory[i] = 0;
}

u8 processor_fetch_byte(struct processor *cpu, struct console *console)
{
    u8 byte = console_read_memory(console, cpu->program_counter);
    cpu->program_counter += 1;
    return byte;
}

void processor_stack_push(struct processor *cpu, u8 value)
{
    cpu->internal_memory[cpu->stack_top] = value;
    cpu->stack_top -= 1;
}

u8 processor_stack_pop(struct processor *cpu)
{
    cpu->stack_top += 1;
    return cpu->internal_memory[cpu->stack_top];
}
