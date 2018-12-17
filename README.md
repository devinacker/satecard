# SateCard

This is a proof-of-concept prototype of a small (~3in²) adapter for the [Satellaview](https://en.wikipedia.org/wiki/Satellaview) which solders onto a [CompactFlash breakout board](https://www.proto-advantage.com/store/product_info.php?products_id=2800022) to add memory-mapped CF card storage to the Satellaview base unit.

In addition, a small example SNES ROM and source code is included which will display some info about a CF card (vendor info, total size, MBR partition table) if one is detected.

## How?

Aside from the Super Famicom's underside expansion port used to connect the Satellaview unit, the Satellaview itself has an internal 38-pin expansion connector which resembles the 2.5-inch IDE/ATA hard drive connector. This similarity isn't a coincidence; [available patent documents](https://imgur.com/a/Nq35L) show that the connector was intended for some sort of never-released hard drive add-on, and recent reverse-engineering efforts revealed that the connector is essentially an IDE connector with fewer pins, no DMA signals, and an 8-bit (rather than 16-bit) data bus. 

In addition, the CompactFlash standard has a "True IDE" compatibility mode which is (theoretically) guaranteed to support 8-bit data buses. CF cards are also capable of operating at 5V, making it easy to interface with "retro" hardware that doesn't use 3.3V components. As a result, this project shows that it is possible to successfully interface CF cards with the Satellaview using a simple physical adapter.

## Why?

Since the Satellaview's internal expansion port was never officially used, no contemporary support for any such expansion hardware is known to exist. This proof of concept is essentially a "what could have been" experiment, rather than an actual enhancement for any existing games. Maybe it'll find a purpose in some sort of homebrew project later on?

The board was designed around a pre-made CF breakout/adapter board mainly for ease of assembly and testing, since I still consider it a "prototype". If this actually manages to turn into a serious product somehow, it may eventually be redesigned to feature a CF slot directly on the board instead.

You can order the board itself [from OSHPark](https://oshpark.com/shared_projects/pUr2RTn3); a minimum order of 3 boards costs exactly $15.00 USD.
