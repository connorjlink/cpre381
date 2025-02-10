quit -sim

vcom -2008 -work work my_enums.vhd
vcom -2008 -work work Driver/*.vhd
vcom -2008 -work work IP/*.vhd
vcom -2008 -work work BGU/*.vhd
vcom -2008 -work work ALU/*.vhd
vcom -2008 -work work Decoder/*.vhd
vcom -2008 -work work *.vhd

# more VCOM here

vsim -voptargs=+acc tb_cpu
do tb_cpu.do 