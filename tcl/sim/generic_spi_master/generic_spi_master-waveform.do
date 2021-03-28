onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /generic_spi_master_tb/DUT/c_cpha
add wave -noupdate /generic_spi_master_tb/DUT/c_cpol
add wave -noupdate /generic_spi_master_tb/RST
add wave -noupdate /generic_spi_master_tb/CLK
add wave -noupdate -divider SPI
add wave -noupdate /generic_spi_master_tb/SCK
add wave -noupdate /generic_spi_master_tb/CSN(0)
add wave -noupdate /generic_spi_master_tb/CSN(1)
add wave -noupdate /generic_spi_master_tb/MOSI
add wave -noupdate /generic_spi_master_tb/MISO
add wave -noupdate -divider Parallel
add wave -noupdate /generic_spi_master_tb/DI_RD(0)
add wave -noupdate /generic_spi_master_tb/DI_RD(1)
add wave -noupdate -radix hexadecimal -childformat {{/generic_spi_master_tb/DI(7) -radix hexadecimal} {/generic_spi_master_tb/DI(6) -radix hexadecimal} {/generic_spi_master_tb/DI(5) -radix hexadecimal} {/generic_spi_master_tb/DI(4) -radix hexadecimal} {/generic_spi_master_tb/DI(3) -radix hexadecimal} {/generic_spi_master_tb/DI(2) -radix hexadecimal} {/generic_spi_master_tb/DI(1) -radix hexadecimal} {/generic_spi_master_tb/DI(0) -radix hexadecimal}} -subitemconfig {/generic_spi_master_tb/DI(7) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DI(6) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DI(5) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DI(4) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DI(3) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DI(2) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DI(1) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DI(0) {-height 18 -radix hexadecimal}} /generic_spi_master_tb/DI
add wave -noupdate /generic_spi_master_tb/DO_WR(0)
add wave -noupdate /generic_spi_master_tb/DO_WR(1)
add wave -noupdate -radix hexadecimal /generic_spi_master_tb/DO
add wave -noupdate -divider Control
add wave -noupdate /generic_spi_master_tb/EN
add wave -noupdate /generic_spi_master_tb/BSY
add wave -noupdate -divider FSM
add wave -noupdate /generic_spi_master_tb/DUT/current_state
add wave -noupdate /generic_spi_master_tb/DUT/next_state
add wave -noupdate -divider Counter
add wave -noupdate -radix unsigned /generic_spi_master_tb/DUT/sck_cntr_cnt
add wave -noupdate /generic_spi_master_tb/DUT/sck_cntr_ld
add wave -noupdate /generic_spi_master_tb/DUT/sck_cntr_en
add wave -noupdate /generic_spi_master_tb/DUT/sck_cntr_is_init
add wave -noupdate /generic_spi_master_tb/DUT/sck_cntr_is_zero
add wave -noupdate -radix unsigned /generic_spi_master_tb/DUT/bit_cntr_cnt
add wave -noupdate /generic_spi_master_tb/DUT/bit_cntr_ld
add wave -noupdate /generic_spi_master_tb/DUT/bit_cntr_en
add wave -noupdate /generic_spi_master_tb/DUT/bit_cntr_is_zero
add wave -noupdate /generic_spi_master_tb/DUT/bit_cntr_is_init
add wave -noupdate -radix unsigned -childformat {{/generic_spi_master_tb/DUT/cs_cntr_cnt(1) -radix unsigned} {/generic_spi_master_tb/DUT/cs_cntr_cnt(0) -radix unsigned}} -subitemconfig {/generic_spi_master_tb/DUT/cs_cntr_cnt(1) {-height 18 -radix unsigned} /generic_spi_master_tb/DUT/cs_cntr_cnt(0) {-height 18 -radix unsigned}} /generic_spi_master_tb/DUT/cs_cntr_cnt
add wave -noupdate /generic_spi_master_tb/DUT/cs_cntr_is_zero
add wave -noupdate /generic_spi_master_tb/DUT/cs_cntr_en
add wave -noupdate /generic_spi_master_tb/DUT/cs_cntr_zero
add wave -noupdate -divider SFR
add wave -noupdate -radix hexadecimal -childformat {{/generic_spi_master_tb/DUT/mosi_sfr(7) -radix hexadecimal} {/generic_spi_master_tb/DUT/mosi_sfr(6) -radix hexadecimal} {/generic_spi_master_tb/DUT/mosi_sfr(5) -radix hexadecimal} {/generic_spi_master_tb/DUT/mosi_sfr(4) -radix hexadecimal} {/generic_spi_master_tb/DUT/mosi_sfr(3) -radix hexadecimal} {/generic_spi_master_tb/DUT/mosi_sfr(2) -radix hexadecimal} {/generic_spi_master_tb/DUT/mosi_sfr(1) -radix hexadecimal} {/generic_spi_master_tb/DUT/mosi_sfr(0) -radix hexadecimal}} -subitemconfig {/generic_spi_master_tb/DUT/mosi_sfr(7) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DUT/mosi_sfr(6) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DUT/mosi_sfr(5) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DUT/mosi_sfr(4) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DUT/mosi_sfr(3) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DUT/mosi_sfr(2) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DUT/mosi_sfr(1) {-height 18 -radix hexadecimal} /generic_spi_master_tb/DUT/mosi_sfr(0) {-height 18 -radix hexadecimal}} /generic_spi_master_tb/DUT/mosi_sfr
add wave -noupdate /generic_spi_master_tb/DUT/mosi_load
add wave -noupdate /generic_spi_master_tb/DUT/mosi_shift
add wave -noupdate -radix hexadecimal /generic_spi_master_tb/DUT/miso_sfr
add wave -noupdate /generic_spi_master_tb/DUT/miso_shift
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {8210000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 361
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
WaveRestoreZoom {0 ps} {23336640 ps}
