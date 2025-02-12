quit -sim

vcom -2008 -work work Registers/my_records.vhd
vcom -2008 -work work ../SingleCycleRISCV/RISCV_types.vhd
vcom -2008 -work work ../Lab2RISCV/Lab2_submit/RegFile/RISCV_types.vhd

vcom -2008 -work work ../Lab1/andg2.vhd
vcom -2008 -work work ../Lab1/org2.vhd
vcom -2008 -work work ../Lab1/xorg2.vhd
vcom -2008 -work work ../Lab1/invg.vhd
vcom -2008 -work work ../Lab1/Lab1_submit/Mux/*.vhd
vcom -2008 -work work ../Lab1/Lab1_submit/OnesComp/*.vhd
vcom -2008 -work work ../Lab1/Lab1_submit/Adder/*.vhd
vcom -2008 -work work ../Lab1/Lab1_submit/AddSub/*.vhd

vcom -2008 -work work ../Lab2RISCV/Lab2_submit/Extenders/*.vhd
vcom -2008 -work work ../Lab2RISCV/Lab2_submit/Memory/*.vhd
vcom -2008 -work work ../Lab2RISCV/Lab2_submit/RegFile/*.vhd

vcom -2008 -work work ../SingleCycleRISCV/*.vhd
vcom -2008 -work work ../SingleCycleRISCV/Driver/*.vhd
vcom -2008 -work work ../SingleCycleRISCV/IP/*.vhd
vcom -2008 -work work ../SingleCycleRISCV/BGU/*.vhd
vcom -2008 -work work ../SingleCycleRISCV/ALU/*.vhd
vcom -2008 -work work ../SingleCycleRISCV/Decoder/*.vhd

vcom -2008 -work work Registers/*.vhd
vcom -2008 -work work *.vhd

# more VCOM here

vsim -voptargs=+acc tb_software_cpu
do tb_software_cpu.do 