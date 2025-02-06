-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- bgu.vhd
-- DESCRIPTION: This file contains an implementation of a basic RISC-V branch generation unit.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.my_enums.all;

entity bgu is
    port(
        i_CLK    : in  std_logic;
        i_DS1    : in  std_logic_vector(31 downto 0);
        i_DS2    : in  std_logic_vector(31 downto 0);
        i_BGUOp  : in  natural;
        o_Branch : out std_logic 
    );
end bgu;

architecture mixed of bgu is

begin

    o_Branch <= '1' when (i_BGUOp = work.my_enums.BEQ and 
                          unsigned(i_DS1) = unsigned(i_DS2)) else

                '1' when (i_BGUOp = work.my_enums.BNE and -- NOTE: this is not division... it's != in VHDL for some reason
                          unsigned(i_DS1) /= unsigned(i_DS2)) else

                '1' when (i_BGUOp = work.my_enums.BLT and
                          signed(i_DS1) < signed(i_DS2)) else

                '1' when (i_BGUOp = work.my_enums.BGE and 
                          signed(i_DS1) >= signed(i_DS2)) else 

                '1' when (i_BGUOp = work.my_enums.BLTU and
                          unsigned(i_DS1) < unsigned(i_DS2)) else

                '1' when (i_BGUOp = work.my_enums.BGEU and
                          unsigned(i_DS1) >= unsigned(i_DS2)) else

                '1' when (i_BGUOp = work.my_enums.J) else

                '0';
    
end mixed;
