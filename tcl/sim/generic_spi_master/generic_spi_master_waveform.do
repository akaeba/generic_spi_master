onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /generic_spi_master_tb/p_stimuli_process/good
add wave -noupdate /generic_spi_master_tb/RST
add wave -noupdate /generic_spi_master_tb/CLK
add wave -noupdate -divider SPI
add wave -noupdate /generic_spi_master_tb/SCK
add wave -noupdate /generic_spi_master_tb/CSN
add wave -noupdate /generic_spi_master_tb/MOSI
add wave -noupdate /generic_spi_master_tb/MISO
add wave -noupdate -divider Parallel
add wave -noupdate /generic_spi_master_tb/DI
add wave -noupdate /generic_spi_master_tb/DO
add wave -noupdate /generic_spi_master_tb/DO_WR
add wave -noupdate /generic_spi_master_tb/DI_RD
add wave -noupdate -divider Control
add wave -noupdate /generic_spi_master_tb/EN
add wave -noupdate /generic_spi_master_tb/BSY
add wave -noupdate -divider FSM
add wave -noupdate /generic_spi_master_tb/DUT/current_state
add wave -noupdate /generic_spi_master_tb/DUT/next_state
add wave -noupdate -divider Counter
add wave -noupdate -radix unsigned /generic_spi_master_tb/DUT/sck_clk_gen_cnt
add wave -noupdate /generic_spi_master_tb/DUT/sck_clk_gen_ld
add wave -noupdate /generic_spi_master_tb/DUT/sck_clk_gen_en
add wave -noupdate /generic_spi_master_tb/DUT/bit_cntr_cnt
add wave -noupdate /generic_spi_master_tb/DUT/bit_cntr_ld
add wave -noupdate /generic_spi_master_tb/DUT/bit_cntr_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4977 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 288
configure wave -valuecolwidth 52
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
WaveRestoreZoom {0 ps} {1114176 ps}
