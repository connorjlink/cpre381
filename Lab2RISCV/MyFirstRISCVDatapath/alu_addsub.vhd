-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- alu_addsub.vhd
-- DESCRIPTION: This files contains an implementation of and 32-bit full adder/subtractor circuit using structural VHDL, generics, and generate statements.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity alu_addsub is
    generic(N : integer := 32);
    port(i_A        : in  std_logic_vector(N-1 downto 0);
         i_B        : in  std_logic_vector(N-1 downto 0);
         i_Imm      : in  std_logic_vector(N-1 downto 0);
         i_ALUSrc   : in  std_logic;
         i_nAdd_Sub : in  std_logic;
         o_S        : out std_logic_vector(N-1 downto 0);
         o_Co       : out std_logic);
end alu_addsub;

architecture structural of alu_addsub is

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

component ext is
    generic(IN_WIDTH  : integer := 12;
            OUT_WIDTH : integer := 32);
	port(i_D          : in  std_logic_vector(IN_WIDTH-1 downto 0);
         i_nZero_Sign : in  std_logic;
         o_Q          : out std_logic_vector(OUT_WIDTH-1 downto 0));
end component;

-- Signal to carry the selected B operand
signal s_B  : std_logic_vector(N-1 downto 0);
-- Signal to carry the inverted input
signal s_Bi : std_logic_vector(N-1 downto 0);
-- Signal to carry the conditional input value
signal s_Bm : std_logic_vector(N-1 downto 0);

begin

    -- Choose between the B operand the immediate data for the second operand
    g_ImmediateSelector: mux2t1_N
        generic MAP(N => N)
        port MAP(i_S  => i_ALUSrc,
                 i_D0 => i_B,
                 i_D1 => i_Imm,
                 o_O  => s_B);

    -- Invert the input
    g_BInverter: comp_N
        generic MAP(N => N)
        port MAP(i_A => s_B,
                 o_F => s_Bi);

    -- Conditionally select input data for add/subtract
    g_AddSubSelector: mux2t1_N
        generic MAP(N => N)
        port MAP(i_S  => i_nAdd_Sub,
                 i_D0 => s_B,
                 i_D1 => s_Bi,
                 o_O  => s_Bm);

    -- Add/subtract the input data
    g_FullAdder: adder_N
        generic MAP(N => N)
        port MAP(i_A  => i_A,
                 i_B  => s_Bm,
                 i_Ci => i_nAdd_Sub,
                 o_S  => o_S,
                 o_Co => o_Co);

end structural;
