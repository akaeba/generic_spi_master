##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           generic_spi_master_mode_0_3-mode=3_CLKDIV=1-runsim.tcl
## @date:           2021-03-21
##
## @brief:          starts simulation
##
##                  Modelsim: Tools -> TCL -> Execute Macro
##************************************************************************



# set up sim
set TCLK_NS	20;									# clock period in nano seconds
set CLKDIV2 1;									# CLK Divider
set LOOPS	20;									# loop iteration in TB
set TSCK_NS [expr {${TCLK_NS}*2*${CLKDIV2}}];	# calc bit shift clock
set TFRM_NS [expr 2*9*${TSCK_NS}+1];			# CSN=2; DW_SFR=8;
set TSIM_NS [expr ${TFRM_NS}*${LOOPS} + 1000];	# total sim time


# start simulation, disable optimization
vsim -novopt -gDO_ALL_TEST=true -gTCLK_NS=${TCLK_NS} -gCLK_DIV2=${CLKDIV2} -gSPI_MODE=3 -t 1ps work.generic_spi_master_mode_0_3_tb

# load Waveform
do "../tcl/sim/generic_spi_master_mode_0_3/generic_spi_master_mode_0_3-waveform.do"

# sim until finish
run ${TSIM_NS} ns
