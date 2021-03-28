##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           generic_spi_master_inp_filter-runsim.tcl
## @date:           2021-02-26
##
## @brief:          starts simulation
##
##                  Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************



# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true -t 1ps work.generic_spi_master_inp_filter_tb

# load Waveform
do "../tcl/sim/generic_spi_master_inp_filter/generic_spi_master_inp_filter-waveform.do"

# sim until finish
run 2.5 us
