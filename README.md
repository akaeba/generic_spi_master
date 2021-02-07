# Generic [SPI](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface) Master

An easy customizable multi chip select supporting _Serial Peripheral Interface_ (SPI) Master.


## Key features


## Releases



## SPI Modes

<center><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/SPI_timing_diagram.svg/2000px-SPI_timing_diagram.svg.png" height="50%" width="50%" alt="Wikimedia timing diagram SPI modes" title="SPI modes timing diagram" /></center>


## Resource allocation

| Technology        | Logic | Registers | BRAM | Fmax   |
| ----------------- | ----- | --------- | ---- | ------ |
| Cyclone 10 (FPGA) |       |           |      |        |


## Example

In this example interfaces the [SPI master](https://github.com/akaeba/generic-spi-master/blob/master/hdl/generic_spi_master.vhd) in mode 2
an parallel-in ([HC165](https://www.ti.com/lit/ds/symlink/sn74hc165.pdf)) and parallel-out ([HC594](https://www.ti.com/lit/ds/symlink/sn74hc594.pdf)) 
shift register.

<center><img src="https://github.com/akaeba/generic-spi-master/blob/master/doc/readme/spi_master_hc594_hc165_access.png" height="110%" width="110%" alt="SPI master interfaces shift register HC594 and HC165 and one data byte is transferred" title="SPI master interfaces shift register HC594 and HC165" /></center>


## References

 * [Wikipedia: SPI](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface)
