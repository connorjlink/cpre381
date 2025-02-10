set NumericStdNoWarnings 1
run 0 ps
set NumericStdNoWarnings 0

mem load -infile dmem.hex -format hex /tb_cpu/DUT0/g_CPUDataMemory
mem load -infile imem.hex -format hex /tb_cpu/DUT0/g_CPUInstructionMemory
mem load -infile zero.hex -format hex /tb_cpu/DUT0/g_CPURegisterFile/s_Rx

run 600