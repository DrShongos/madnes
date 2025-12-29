package main

import "console"
import "core:fmt"

main :: proc() {
    nes := console.console_new()

    for {
        console.console_tick(&nes)
    }
}
