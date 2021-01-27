##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           generic_spi_master_compile
## @date:           2021-01-27
##
## @brief:          compile script
##
##					Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************



# path setting
#
set proj_dir "../"
#



# Compile Design
#
vcom -93 ${proj_dir}/hdl/generic_spi_master.vhd
#



# Compile TB
#
vcom -93 ${proj_dir}/tb/generic_spi_master_tb.vhd
#
