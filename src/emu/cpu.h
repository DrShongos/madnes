#pragma once

#include "../common.h"

#define TEST_ROM_START 0xC000
#define CPU_MEM_MAX_INDEX 0xFFFF

#define CPU_MEM_SIZE CPU_MEM_MAX_INDEX + 1

#define STACK_TOP_START 0xFD

#define PROCESSOR_DEFAULT_STATUS 0x24

struct console;

enum processor_status_flags {
    STATUS_FLAG_CARRY = 0x01,
    STATUS_FLAG_ZERO = 0x02,
    STATUS_FLAG_INTERRUPT_DISABLE = 0x04,
    STATUS_FLAG_DECIMAL_MODE = 0x08, // Ignored by NES,
    STATUS_FLAG_BREAK = 0x10,

    STATUS_FLAG_ALWAYS_1 = 0x20,
    STATUS_FLAG_OVERFLOW = 0x40,
    STATUS_FLAG_NEGATIVE = 0x80,
};

struct processor {
    enum processor_status_flags status_flags;
    u8 cycle;

    // CPU Registers
    u8 register_x;
    u8 register_y;
    u8 accumulator;
    u8 stack_top;

    u16 program_counter;

    u8 internal_memory[CPU_MEM_SIZE];
};

void processor_reset(struct processor *cpu);
u8 processor_fetch_byte(struct processor *cpu, struct console* console);

void processor_stack_push(struct processor *cpu, u8 value);
u8 processor_stack_pop(struct processor *cpu);
