-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- adder_N.vhd
-- DESCRIPTION: This files contains an implementation of and N-bit-wide full adder circuit using structural VHDL, generics, and generate statements.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity adder_N is
    generic(N : integer := 32);
    port(i_A  : in  std_logic_vector(N-1 downto 0);
         i_B  : in  std_logic_vector(N-1 downto 0);
         i_Ci : in  std_logic;
         o_S  : out std_logic_vector(N-1 downto 0);
         o_Co : out std_logic);
end adder_N;

architecture mixed of adder_N is

component adder is
	port(i_A  : in  std_logic;
	     i_B  : in  std_logic;
	     i_Ci : in  std_logic;
	     o_S  : out std_logic;
	     o_Co : out std_logic);
end component;

-- Signal to carry the intermediate rippled carry out values
signal s_C : std_logic_vector(N downto 0);

begin

    -- TODO: does this even work?
    s_C(0) <= i_Ci;
    o_Co <= s_C(N);

    g_NBit_Adder: for i in 0 to N-1
    generate
        ADDERI: adder port MAP(i_A => i_A(i),
                               i_B => i_B(i),
                               i_Ci => s_C(i),
                               o_S => o_S(i),
                               o_Co => s_C(i + 1));
    end generate g_NBit_Adder;

end mixed;
