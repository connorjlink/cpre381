#########################################################################
## Connor Link
## Iowa State University
#########################################################################
## tb_software_cpu.do
#########################################################################
## DESCRIPTION: This file contains a do file for the testbench for the 
##              software_cpu entity. It adds some useful signals for testing
##              functionality and debugging the system. It also formats
##              the waveform and runs the simulation.
#########################################################################

set NumericStdNoWarnings 1
run 0 ps
set NumericStdNoWarnings 0

mem load -infile ../test/fibonacci/program.hex -format hex /tb_software_cpu/DUT0/SoftwareCPU_InstructionMemory
mem load -infile ../test/zero.hex -format hex /tb_software_cpu/DUT0/SoftwareCPU_RegisterFile/s_Rx

# Setup the wave form with useful signals

# Add the standard, non-data clock and reset input signals.
# First, add a helpful header label.
add wave -noupdate -divider {Standard Inputs}
add wave -noupdate -label CLK /tb_software_cpu/CLK
add wave -noupdate -label CLK /tb_software_cpu/DUT0/g_CLK
add wave -noupdate -label reset /tb_software_cpu/reset

# Add data inputs that are specific to this design. These are the ones set during our test cases.
# Note that I've set the radix to unsigned, meaning that the values in the waveform will be displayed
# as unsigned decimal values. This may be more convenient for your debugging. However, you should be
# careful to look at the radix specifier (e.g., the decimal value 32'd10 is the same as the hexidecimal
# value 32'hA.
#add wave -noupdate -divider {Data Inputs}
#add wave -noupdate -radix hexadecimal /tb_software_cpu/s_iInsn

# INPUT/OUTPUT added here
#add wave -noupdate -divider {Data Input/Outputs}

# Add data outputs that are specific to this design. These are the ones that we'll check for correctness.
add wave -noupdate -divider {Instruction Pointer}
add wave -noupdate -radix hexadecimal /tb_software_cpu/DUT0/SoftwareCPU_InstructionPointer/*

add wave -noupdate -divider {Data Memory}
add wave -noupdate -radix hexadecimal /tb_software_cpu/DUT0/SoftwareCPU_DataMemory/*

add wave -noupdate -divider {Register File}
add wave -noupdate -radix hexadecimal /tb_software_cpu/DUT0/SoftwareCPU_RegisterFile/*

add wave -noupdate -divider {ALU}
add wave -noupdate -radix hexadecimal /tb_software_cpu/DUT0/SoftwareCPU_ALU/*

add wave -noupdate -divider {Driver}
add wave -noupdate -radix hexadecimal /tb_software_cpu/DUT0/SoftwareCPU_Driver/*

add wave -noupdate -divider {Misc Data Outputs}
add wave -noupdate -radix hexadecimal /tb_software_cpu/DUT0/*
#add wave -noupdate -radix hexadecimal /tb_software_cpu/DUT0/SoftwareCPU_RegisterFile/*


# Add the standard, non-data clock and reset input signals again.
# As you develop more complicated designs with many more signals, you will probably find it helpful to
# add these signals at multiple points within your waveform so you can easily see cycle behavior, etc.
#add wave -noupdate -divider {Standard Inputs}
#add wave -noupdate /tb_software_cpu/CLK
#add wave -noupdate /tb_software_cpu/reset

# Add some internal signals. As you debug you will likely want to trace the origin of signals
# back through your design hierarchy which will require you to add signals from within sub-components.
# These are provided just to illustrate how to do this. Note that any signals that are not added to
# the wave prior to the run command may not have their values stored during simulation. Therefore, if
# you decided to add them after simulation they will appear as blank.
# Note that I've left the radix of these signals set to the default, which, for me, is hexidecimal.
#add wave -noupdate -divider {Internal Design Signals}
#add wave -noupdate /tb_software_cpu/DUT0/g_Weight/iLd
#add wave -noupdate /tb_software_cpu/DUT0/g_Weight/sQ
#add wave -noupdate /tb_software_cpu/DUT0/g_Weight/oQ

# The following command will add all of the signals within the DUT0 module's scope (but not internal
# signals to submodules).
#add wave -noupdate /tb_software_cpu/DUT0/*

# TODO: Add your own signals as needed!



# Run for 100 timesteps (default is 1ns per timestep, but this can be modified so be aware).
run 1000