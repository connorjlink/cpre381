quit -sim

vcom -2008 -work work Registers/*.vhd
vcom -2008 -work work *.vhd

# more VCOM here

vsim -voptargs=+acc tb_software_cpu
do tb_software_cpu.do 