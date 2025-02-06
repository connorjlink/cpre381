-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- comp_H.vhd
-- DESCRIPTION: This file contains an implementation of an N-bit-wide one's complementor using strucutral VHDL, generics, and generate statements.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity comp_N is
    generic(N : integer := 32);
    port(i_A : in  std_logic_vector(N-1 downto 0);
         o_F : out std_logic_vector(N-1 downto 0));
end comp_N;

architecture structural of comp_N is

component invg is
    port(i_A : in  std_logic;
         o_F : out std_logic);
end component;

begin

    -- Instantiate N "not" instances
    g_Nbit_Not: for i in 0 to N-1 generate
        NOTI: invg port MAP(i_A => i_A(i),
                            o_F => o_F(i));
    end generate g_Nbit_Not;

end structural;
