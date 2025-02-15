quit -sim

vcom -2008 -work work Registers/my_records.vhd
vcom -2008 -work work ../riscv/proj/src/RISCV_types.vhd
vcom -2008 -work work ../riscv/proj/src/*.vhd
vcom -2008 -work work ../riscv/proj/src/TopLevel/*.vhd

vcom -2008 -work work Registers/*.vhd
vcom -2008 -work work SW/*vhd

vsim -voptargs=+acc tb_SW_RISCV_Processor
do SW/tb_SW_RISCV_Processor.do
