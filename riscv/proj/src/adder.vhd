-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- adder.vhd
-- DESCRIPTION: This files contains an implementation of an 1-bit-wide full adder circuit using structural VHDL, generics, and generate statements.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity adder is
    port(i_A  : in  std_logic;
         i_B  : in  std_logic;
         i_Ci : in  std_logic;
         o_S  : out std_logic;
         o_Co : out std_logic);
end adder;

architecture structural of adder is

component xorg2 is
	port(i_A : in  std_logic;
             i_B : in  std_logic;
             o_F : out std_logic);
end component;

component andg2 is
	port(i_A : in  std_logic;
             i_B : in  std_logic;
             o_F : out std_logic);
end component;

component org2 is
	port(i_A : in  std_logic;
	     i_B : in  std_logic;
	     o_F : out std_logic);
end component;


-- Signal to carry intermediate generated sum
signal s_S : std_logic;
-- Signal to carry intermediate generated carry
signal s_C0 : std_logic;
-- Signal to carry intermediate generated carry
signal s_C1 : std_logic;

begin

    -- Level 1: generate the sum value components
    g_PartialSum: xorg2
        port MAP(i_A => i_A,
                 i_B => i_B,
                 o_F => s_S);

    -- Level 2: generate the carry out value components
    g_PartialCarry1: andg2
        port MAP(i_A => i_A,
                 i_B => i_B,
                 o_F => s_C0);

    g_PartialCarry2: andg2
        port MAP(i_A => s_S,
                 i_B => i_Ci,
                 o_F => s_C1);

    -- Level 3: synthesize final carry out and sum values
    g_Sum: xorg2
        port MAP(i_A => s_S,
                 i_B => i_Ci,
                 o_F => o_S);

    g_Carry: org2
        port MAP(i_A => s_C0,
                 i_B => s_C1,
                 o_F => o_Co);

end structural;
