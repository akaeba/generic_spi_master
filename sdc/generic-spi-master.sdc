##************************************************************************
## @author:         Andreas Kaeberlein
## @copyright:      Copyright 2021
## @credits:        AKAE
##
## @license:        BSDv3
## @maintainer:     Andreas Kaeberlein
## @email:          andreas.kaeberlein@web.de
##
## @file:           generic-spi-master.sdc
## @date:           2021-02-05
##
## @brief:          timing constraints
##
##************************************************************************



# Primary Clocks
#
create_clock -name clk50 -period 20.000 [get_ports {CLK}]
#


# Calculate Clock Uncertainty
# SRC: http://quartushelp.altera.com/14.1/mergedProjects/tafs/tafs/tcl_pkg_sdc_ext_ver_1.0_cmd_derive_clock_uncertainty.htm
#
derive_clock_uncertainty
#


# Input Delay
#
set_input_delay -clock {clk50} 5.0 [get_ports {MISO}];
#


# Output Delay
#
set_output_delay -add_delay -clock {clk50} 5.0 [get_ports {MOSI CSN[*]}];
#
