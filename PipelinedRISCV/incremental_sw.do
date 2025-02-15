quit -sim

vcom -2008 -work work Registers/*.vhd
vcom -2008 -work work SW/*vhd

vsim -voptargs=+acc tb_SW_RISCV_Processor
do SW/tb_SW_RISCV_Processor.do
