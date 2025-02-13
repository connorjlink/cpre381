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

entity addsub_N is
    generic(N : integer := 32);
    port(i_A        : in  std_logic_vector(N-1 downto 0);
         i_B        : in  std_logic_vector(N-1 downto 0);
         i_nAdd_Sub : in  std_logic;
         o_S        : out std_logic_vector(N-1 downto 0);
         o_Co       : out std_logic);
end addsub_N;

architecture structural of addsub_N is

component comp_N is
	generic(N : integer := 32);
	port(i_A : in  std_logic_vector(N-1 downto 0);
         o_F : out std_logic_vector(N-1 downto 0));
end component;

component adder_N is
	generic(N : integer := 32);
    port(i_A  : in  std_logic_vector(N-1 downto 0);
	     i_B  : in  std_logic_vector(N-1 downto 0);
	     i_Ci : in  std_logic;
	     o_S  : out std_logic_vector(N-1 downto 0);
	     o_Co : out std_logic);
end component;

component mux2t1_N is
    generic(N : integer := 32);
    port(i_S  : in  std_logic;
         i_D0 : in  std_logic_vector(N-1 downto 0);
         i_D1 : in  std_logic_vector(N-1 downto 0);
         o_O  : out std_logic_vector(N-1 downto 0));
end component;

-- Signal to carry the inverted input
signal s_Bi : std_logic_vector(N-1 downto 0);
-- Signal to carry the conditional input value
signal s_Bm : std_logic_vector(N-1 downto 0);

begin

    -- Level 0: invert the input
    g_Complementor: comp_N
        generic MAP(N => N)
        port MAP(i_A => i_B,
                 o_F => s_Bi);

    -- Level 1: conditionally select input data for add/subtract
    g_Multiplexer: mux2t1_N
        generic MAP(N => N)
        port MAP(i_S  => i_nAdd_Sub,
                 i_D0 => i_B,
                 i_D1 => s_Bi,
                 o_O  => s_Bm);

    -- Level 2: add/subtract the input data
    g_NBit_Adder: adder_N
        generic MAP(N => N)
        port MAP(i_A  => i_A,
                 i_B  => s_Bm,
                 i_Ci => i_nAdd_Sub,
                 o_S  => o_S,
                 o_Co => o_Co);

end structural;
