onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider General
add wave -noupdate /generic_spi_master_mode_0_3_tb/p_stimuli_process/good
add wave -noupdate /generic_spi_master_mode_0_3_tb/RST
add wave -noupdate /generic_spi_master_mode_0_3_tb/CLK
add wave -noupdate /generic_spi_master_mode_0_3_tb/EN
add wave -noupdate /generic_spi_master_mode_0_3_tb/BSY
add wave -noupdate -divider SPI
add wave -noupdate /generic_spi_master_mode_0_3_tb/CSN(0)
add wave -noupdate /generic_spi_master_mode_0_3_tb/CSN(1)
add wave -noupdate /generic_spi_master_mode_0_3_tb/SCK
add wave -noupdate /generic_spi_master_mode_0_3_tb/MOSI
add wave -noupdate /generic_spi_master_mode_0_3_tb/MISO
add wave -noupdate -divider {Data IN/OUT}
add wave -noupdate -radix hexadecimal /generic_spi_master_mode_0_3_tb/DI
add wave -noupdate /generic_spi_master_mode_0_3_tb/DI_RD(0)
add wave -noupdate /generic_spi_master_mode_0_3_tb/DI_RD(1)
add wave -noupdate -radix hexadecimal /generic_spi_master_mode_0_3_tb/DO
add wave -noupdate /generic_spi_master_mode_0_3_tb/DO_WR(0)
add wave -noupdate /generic_spi_master_mode_0_3_tb/DO_WR(1)
add wave -noupdate -divider SPI_MASTER
add wave -noupdate /generic_spi_master_mode_0_3_tb/DUT/current_state
add wave -noupdate /generic_spi_master_mode_0_3_tb/DUT/next_state
add wave -noupdate -radix unsigned /generic_spi_master_mode_0_3_tb/DUT/cs_cntr_cnt
add wave -noupdate /generic_spi_master_mode_0_3_tb/DUT/bit_cntr_is_zero
add wave -noupdate -divider SFR
add wave -noupdate -radix hexadecimal /generic_spi_master_mode_0_3_tb/mosi_reg
add wave -noupdate -radix hexadecimal /generic_spi_master_mode_0_3_tb/miso_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {910000 ps} 0}
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
WaveRestoreZoom {0 ps} {4429072 ps}
