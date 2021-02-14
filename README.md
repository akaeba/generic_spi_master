# Generic [SPI](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface) Master

An easy customizable multi chip select supporting _Serial Peripheral Interface_ (SPI) Master.


## Releases


## Key features

* SPI mode 0-3
* arbitrary number of chip-selects (CSN)
* F<sub>SCK,max</sub>=F<sub>CLK</sub>/2
* F<sub>SCK</sub> settable at compile


## Interface

### Generics

| Name       | Type     | Default | Description                                      |
| ---------- | -------- | ------- | ------------------------------------------------ |
| SPI_MODE   | integer  | 0       | active transfer mode                             |
| NUM_CS     | positive | 1       | available chip-selects                           |
| DW_SFR     | integer  | 8       | SPI shift register data width                    |
| CLK_HZ     | positive | 50M     | clock frequency                                  |
| SCK_HZ     | positive | 1M      | bit clock frequency                              |
| RST_ACTIVE | bit      | 1       | logic level for active reset; 1: high-active     |
| MISO_SYNC  | natural  | 0       | MISO data input synchronization flip-flop stages |
| MISO_FILT  | natural  | 0       | MISO input filter stages, implements hysteresis  |

_Generics are settable while compile time._


### Ports

| Port     | Direction | Width  | Description                                        |
| -------- | --------- | ------ | -------------------------------------------------- |
| RST      | input     | 1b     | asynchronous reset                                 |



## SPI Modes

|  SPI Mode | CPOL | CPHA |
| --------- | ---- | ---- |
|  0        |  0   |   0  |
|  1        |  0   |   1  |
|  2        |  1   |   0  |
|  3        |  1   |   1  |

<center><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/SPI_timing_diagram.svg/2000px-SPI_timing_diagram.svg.png" height="50%" width="50%" alt="Wikimedia timing diagram SPI modes" title="SPI modes timing diagram" /></center>


## Architecture


## Timing

<center><img src="./doc/readme/spi_if_timing.svg" height="125%" width="125%" alt="SPI Master timing diagram for interface handling" title="Interface timing diagram" /></center>


## Resource allocation

| Technology        | Logic | Registers | BRAM | Fmax   |
| ----------------- | ----- | --------- | ---- | ------ |
| Cyclone 10 (FPGA) |       |           |      |        |


## Example

In this example interfaces the [SPI master](./hdl/generic_spi_master.vhd) in mode 2 an parallel-in ([HC165](https://www.ti.com/lit/ds/symlink/sn74hc165.pdf))
and parallel-out ([HC594](https://www.ti.com/lit/ds/symlink/sn74hc594.pdf)) shift register.
The waveform shows the [testbenchs](./tb/generic_spi_master_HC594_HC165_tb.vhd) output.

<center><img src="./doc/readme/spi_master_hc594_hc165_access.png" height="110%" width="110%" alt="SPI master interfaces shift register HC594 and HC165 and one data byte is transferred" title="SPI master interfaces shift register HC594 and HC165" /></center>


## References

* [Wikipedia: SPI](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface)
