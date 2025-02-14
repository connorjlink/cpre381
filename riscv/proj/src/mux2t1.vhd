-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- mux2t1.vhd
-- DESCRIPTION: This file contains an implementation of a simple 2:1 multiplexer
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity mux2t1 is
    port(i_D0 : in  std_logic;
         i_D1 : in  std_logic;
         i_S  : in  std_logic;
         o_O  : out std_logic);
end mux2t1;

architecture structural of mux2t1 is

component invg is
    port(i_A : in  std_logic;
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

-- Signal to carry inverted S input
signal s_Sn : std_logic;
-- Signal to carry masked D0 input
signal s_D0 : std_logic;
-- Signal to carry masked D1 input
signal s_D1 : std_logic;

begin

    -- Level 0: invert S
    g_Not: invg
        port MAP(i_A => i_S,
                 o_F => s_Sn);

    -- Level 1: mask D0 with Sn
    g_Mask1: andg2
        port MAP(i_A => s_Sn,
                 i_B => i_D0,
                 o_F => s_D0);

    g_Mask2: andg2
        port MAP(i_A => i_S,
                 i_B => i_D1,
                 o_F => s_D1);

    -- Level 2: combine masked values to output
    g_Combine: org2
        port MAP(i_A => s_D0,
                 i_B => s_D1,
                 o_F => o_O);

end structural;
