#########################################################################
## Connor Link
## Iowa State University
#########################################################################
## tb_SW_RISCV_Processor.do
#########################################################################
## DESCRIPTION: This file contains a do file for the testbench for the 
##              SW_RISCV_Processor entity. It adds some useful signals for testing
##              functionality and debugging the system. It also formats
##              the waveform and runs the simulation.
#########################################################################

set NumericStdNoWarnings 1
run 0 ps
set NumericStdNoWarnings 0

#mem load -infile ../test/fibonacci/program.hex -format hex /tb_SW_RISCV_Processor/DUT0/IMem
mem load -infile ../test/fibonacci_sw/program.hex -format hex /tb_SW_RISCV_Processor/DUT0/IMem
mem load -infile ../test/zero.hex -format hex /tb_SW_RISCV_Processor/DUT0/SoftwareCPU_RegisterFile/s_Rx

add wave -noupdate -divider {Standard Inputs}
add wave -noupdate -label CLK /tb_SW_RISCV_Processor/CLK
add wave -noupdate -label CLK /tb_SW_RISCV_Processor/DUT0/s_gCLK
add wave -noupdate -label reset /tb_SW_RISCV_Processor/reset

add wave -noupdate -divider {Data Input/Outputs}
add wave -noupdate -radix hexadecimal /tb_SW_RISCV_Processor/DUT0/*
add wave -noupdate -radix hexadecimal /tb_SW_RISCV_Processor/DUT0/SoftwareCPU_RegisterFile/s_Rx


run 1000
