onerror {resume}
quietly virtual signal -install /generic_spi_master_hc594_hc165_tb/i_HC165 { (context /generic_spi_master_hc594_hc165_tb/i_HC165 )(A & B & C & D & E & F & G & H )} A_H
quietly virtual signal -install /generic_spi_master_hc594_hc165_tb/i_HC165 { (context /generic_spi_master_hc594_hc165_tb/i_HC165 )(H & G & F & E & D & C & B & A )} H_A
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider General
add wave -noupdate /generic_spi_master_hc594_hc165_tb/p_stimuli_process/good
add wave -noupdate /generic_spi_master_hc594_hc165_tb/XRST
add wave -noupdate /generic_spi_master_hc594_hc165_tb/CLK
add wave -noupdate -divider SPI
add wave -noupdate /generic_spi_master_hc594_hc165_tb/SCK
add wave -noupdate /generic_spi_master_hc594_hc165_tb/CSN(0)
add wave -noupdate /generic_spi_master_hc594_hc165_tb/MOSI
add wave -noupdate /generic_spi_master_hc594_hc165_tb/MISO
add wave -noupdate -divider {SPI Master}
add wave -noupdate /generic_spi_master_hc594_hc165_tb/EN
add wave -noupdate /generic_spi_master_hc594_hc165_tb/BSY
add wave -noupdate /generic_spi_master_hc594_hc165_tb/DI_RD(0)
add wave -noupdate -radix hexadecimal -childformat {{/generic_spi_master_hc594_hc165_tb/DI(7) -radix hexadecimal} {/generic_spi_master_hc594_hc165_tb/DI(6) -radix hexadecimal} {/generic_spi_master_hc594_hc165_tb/DI(5) -radix hexadecimal} {/generic_spi_master_hc594_hc165_tb/DI(4) -radix hexadecimal} {/generic_spi_master_hc594_hc165_tb/DI(3) -radix hexadecimal} {/generic_spi_master_hc594_hc165_tb/DI(2) -radix hexadecimal} {/generic_spi_master_hc594_hc165_tb/DI(1) -radix hexadecimal} {/generic_spi_master_hc594_hc165_tb/DI(0) -radix hexadecimal}} -subitemconfig {/generic_spi_master_hc594_hc165_tb/DI(7) {-height 18 -radix hexadecimal} /generic_spi_master_hc594_hc165_tb/DI(6) {-height 18 -radix hexadecimal} /generic_spi_master_hc594_hc165_tb/DI(5) {-height 18 -radix hexadecimal} /generic_spi_master_hc594_hc165_tb/DI(4) {-height 18 -radix hexadecimal} /generic_spi_master_hc594_hc165_tb/DI(3) {-height 18 -radix hexadecimal} /generic_spi_master_hc594_hc165_tb/DI(2) {-height 18 -radix hexadecimal} /generic_spi_master_hc594_hc165_tb/DI(1) {-height 18 -radix hexadecimal} /generic_spi_master_hc594_hc165_tb/DI(0) {-height 18 -radix hexadecimal}} /generic_spi_master_hc594_hc165_tb/DI
add wave -noupdate /generic_spi_master_hc594_hc165_tb/DO_WR(0)
add wave -noupdate -radix hexadecimal /generic_spi_master_hc594_hc165_tb/DO
add wave -noupdate /generic_spi_master_hc594_hc165_tb/DUT/current_state
add wave -noupdate /generic_spi_master_hc594_hc165_tb/DUT/next_state
add wave -noupdate -divider HC594
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC594/SHCP
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC594/STCP
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC594/SHRN
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC594/STRN
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC594/DS
add wave -noupdate -radix hexadecimal /generic_spi_master_hc594_hc165_tb/i_HC594/Q
add wave -noupdate -divider HC165
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC165/SH_XLD
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC165/CLK
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC165/CLK_INH
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC165/SER
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC165/QH
add wave -noupdate /generic_spi_master_hc594_hc165_tb/i_HC165/XQH
add wave -noupdate -radix hexadecimal /generic_spi_master_hc594_hc165_tb/i_HC165/H_A
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {210000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 404
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {9450 ns}
