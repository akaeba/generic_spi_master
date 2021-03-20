##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           generic_spi_master_mode_0_3_compile.tcl
## @date:           2021-02-06
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
vcom -93 ${proj_dir}/hdl/generic_spi_master_inp_filter.vhd
vcom -93 ${proj_dir}/hdl/generic_spi_master.vhd
#



# Compile TB
#
vcom -93 ${proj_dir}/tb/generic_spi_master_mode_0_3_tb.vhd;
#
