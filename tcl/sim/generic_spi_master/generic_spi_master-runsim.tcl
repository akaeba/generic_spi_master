##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           generic_spi_master-runsim.tcl
## @date:           2021-01-27
##
## @brief:          starts simulation
##
##					Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************



# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true -t 1ps work.generic_spi_master_tb

# load Waveform
do "../tcl/sim/generic_spi_master/generic_spi_master-waveform.do"
