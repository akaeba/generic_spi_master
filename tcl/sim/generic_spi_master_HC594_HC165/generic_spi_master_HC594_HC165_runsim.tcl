##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           generic_spi_master_HC594_HC165_runsim.tcl
## @date:           2021-02-02
##
## @brief:          starts simulation
##
##                  Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************



# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true -t 1ps work.generic_spi_master_HC594_HC165_tb

# load Waveform
do "../tcl/sim/generic_spi_master_HC594_HC165/generic_spi_master_HC594_HC165_waveform.do"

# sim until finish
run 9 us
