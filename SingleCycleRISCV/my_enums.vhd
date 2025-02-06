library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package my_enums is

-- Corresponding func3 values for each branch type
constant BEQ  : natural := 1;
constant BNE  : natural := 2;
constant BLT  : natural := 3;
constant BGE  : natural := 4;
constant BLTU : natural := 5;
constant BGEU : natural := 6;
constant J    : natural := 7; -- force jump for `jal` and `jalr`

-- Corresponding to each load/store data width
constant BYTE   : natural := 0;
constant HALF   : natural := 1;
constant WORD   : natural := 2;
constant DOUBLE : natural := 3;

-- Corresponding to each ALU operation code input signal
constant ADD  : natural := 0;
constant SUB  : natural := 1;
constant BAND : natural := 2;
constant BOR  : natural := 3;
constant BXOR : natural := 4;
constant BSLL : natural := 5;
constant BSRL : natural := 6;
constant BSRA : natural := 7;
constant SLT  : natural := 8;
constant SLTU : natural := 9;

end package my_enums;