quit -sim

vcom -2008 -work work RISCV_types.vhd
vcom -2008 -work work *.vhd
vcom -2008 -work work TopLevel/*.vhd

# more VCOM here

vsim -voptargs=+acc tb_RISCV_Processor

set NumericStdNoWarnings 1
run 0 ps
set NumericStdNoWarnings 0

#mem load -infile ../../../test/exhaustive/program.hex -format hex /tb_RISCV_Processor/DUT0/IMEM
mem load -infile ../../output/simplebranch.s/imem.hex -format hex /tb_RISCV_Processor/DUT0/IMEM
mem load -infile ../../../test/zero.hex -format hex /tb_RISCV_Processor/DUT0/SWCPU_RegisterFile/s_Rx

add wave -noupdate -divider {Standard Inputs}
add wave -noupdate -label CLK /tb_RISCV_Processor/CLK
add wave -noupdate -label reset /tb_RISCV_Processor/reset

add wave -noupdate -divider {Data Inputs/Outputs}
add wave -noupdate -radix hexadecimal /tb_RISCV_Processor/DUT0/*

run 1000