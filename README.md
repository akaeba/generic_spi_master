# Generic [SPI](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface) Master

An easy customizable multi chip select supporting _Serial Peripheral Interface_ (SPI) Master.


## Releases

| Version                                              | Date       | Source                                                                                                | Change log                                                                               |
| ---------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| latest                                               |            | <a id="raw-url" href="https://github.com/akaeba/generic_spi_master/archive/master.zip">latest.zip</a> |                                                                                          |


## Key features

* SPI mode 0-3
* Arbitrary number of chip-selects (CSN)
* Adjustable shift register width
* F<sub>SCK,max</sub>=F<sub>CLK</sub>/2
* F<sub>SCK</sub> settable at compile
* MISO input filter
* round-robin CSN arbitration, starting at low index
* no parallel buffer registers for minimal resource footprint


## Interface

### Generics

| Name          | Type     | Default    | Description                                                          |
| ------------- | -------- | ---------- | -------------------------------------------------------------------- |
| SPI_MODE      | integer  | 0          | used transfer mode                                                   |
| NUM_CS        | positive | 1          | Number of Channels (chip-selects)                                    |
| DW_SFR        | integer  | 8          | data width serial in/out shift register                              |
| CLK_HZ        | positive | 50_000_000 | clock frequency                                                      |
| SCK_HZ        | positive | 1_000_000  | Bit clock rate - can be higher due numeric rounding effects          |
| RST_ACTIVE    | bit      | 1          | Reset active level                                                   |
| MISO_SYNC_STG | natural  | 0          | number of MISO sync stages, 0: not implemented                       |
| MISO_FILT_STG | natural  | 0          | number of evaluated sample bits for hysteresis, 0/1: not implemented |

_Hint: settable at compile time._


### Ports

| Port  | Direction | Width  | Description                                                  |
| ----- | --------- | ------ | ------------------------------------------------------------ |
| RST   | in        | 1      | asynchronous reset                                           |
| CLK   | in        | 1      | clock (rising edge)                                          |
| CSN   | out       | NUM_CS | chip select                                                  |
| SCK   | out       | 1      | shift forward clock                                          |
| MOSI  | out       | 1      | serial data out (master-out-slave-in)                        |
| MISO  | in        | 1      | serial data in  (master-in-slave-out)                        |
| DI    | in        | DW_SFR | Parallel data-in, transmitted via MOSI                       |
| DO    | out       | DW_SFR | Parallel data-out, received via MISO                         |
| EN    | in        | 1      | start transfer                                               |
| BSY   | out       | 1      | transmission active                                          |
| DI_RD | out       | NUM_CS | load MOSI SFR with data; indexes CSN aligned                 |
| DO_WR | out       | NUM_CS | store MISO SFR data in capture register; indexes CSN aligned |


## SPI Modes

|  SPI Mode | CPOL | CPHA |
| --------- | ---- | ---- |
|  0        |  0   |   0  |
|  1        |  0   |   1  |
|  2        |  1   |   0  |
|  3        |  1   |   1  |

<br/>
<center><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/SPI_timing_diagram.svg/2000px-SPI_timing_diagram.svg.png" height="50%" width="50%" alt="Wikimedia timing diagram SPI modes" title="SPI modes timing diagram" /></center>
<br/>


## Architecture

<br/>
<center><img src="./doc/readme/generic_spi_master_arch.svg" height="90%" width="90%" alt="major components of generic spi master as block level diagram" title="generic spi master simplified architecture" /></center>
<br/>


## Timing

<br/>
<center><img src="./doc/readme/spi_if_timing.svg" height="125%" width="125%" alt="SPI Master timing diagram for interface handling" title="Interface timing diagram" /></center>
<br/>


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
