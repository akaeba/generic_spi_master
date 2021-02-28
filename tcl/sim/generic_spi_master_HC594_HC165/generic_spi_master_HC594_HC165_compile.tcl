##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           generic_spi_master_HC594_HC165_compile.tcl
## @date:           2021-02-02
##
## @brief:          compile script
##
##                  Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************



# path setting
#
set proj_dir "../"
#



# Compile Design
#
vcom -93 ${proj_dir}/hdl/generic_spi_master.vhd
vcom -93 ${proj_dir}/hdl/generic_spi_master_inp_filter.vhd
#



# Compile TB
#
vcom -93 ${proj_dir}/tb/HC165.vhd;                              # 8-Bit Parallel-Load Shift Registers
vcom -93 ${proj_dir}/tb/HC594.vhd;                              # 8-bit shift register with output register
vcom -93 ${proj_dir}/tb/generic_spi_master_HC594_HC165_tb.vhd;  #
#
