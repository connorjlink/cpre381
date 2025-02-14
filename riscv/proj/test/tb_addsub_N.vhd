-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_addsub_N.vhd
-- DESCRIPTION: This file contains a testbench to verify the addsub_N.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O

entity tb_addsub_N is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32);
end tb_addsub_N;

architecture mixed of tb_addsub_N is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component addsub_N is
    generic(N : integer := 32);
    port(i_A        : in  std_logic_vector(N-1 downto 0);
         i_B        : in  std_logic_vector(N-1 downto 0);
         i_nAdd_Sub : in  std_logic;
         o_S        : out std_logic_vector(N-1 downto 0);
         o_Co       : out std_logic);
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal s_iA        : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
signal s_iB        : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
signal s_inAdd_Sub : std_logic := '0';
signal s_oS        : std_logic_vector(DATA_WIDTH-1 downto 0);
signal s_oCo       : std_logic; 

begin

-- Instantiate the module under test
DUT0: addsub_N
    generic MAP(N => DATA_WIDTH)
	port MAP(i_A        => s_iA,
 		     i_B        => s_iB,
		     i_nAdd_Sub => s_inAdd_Sub,
		     o_S        => s_oS,
             o_Co       => s_oCo);


--This first process is to setup the clock for the test bench
P_CLK: process
begin
	CLK <= '1';         -- clock starts at 1
	wait for gCLK_HPER; -- after half a cycle
	CLK <= '0';         -- clock becomes a 0 (negative edge)
	wait for gCLK_HPER; -- after half a cycle, process begins evaluation again
end process;

-- This process resets the sequential components of the design.
-- It is held to be 1 across both the negative and positive edges of the clock
-- so it works regardless of whether the design uses synchronous (pos or neg edge)
-- or asynchronous resets.
P_RST: process
begin
	reset <= '0';   
	wait for gCLK_HPER/2;
	reset <= '1';
	wait for gCLK_HPER*2;
	reset <= '0';
	wait;
end process;  


-- Assign inputs 
P_TEST_CASES: process
begin
	wait for gCLK_HPER;
	wait for gCLK_HPER/2; -- don't change inputs on clock edges

	-- Test Case 1:
	s_iA  <= x"00000000";
	s_iB  <= x"00000000";
	s_inAdd_Sub <= '0';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be $00, s_oCo to be 0

    -- Test Case 2:
	s_iA  <= x"00000007";
	s_iB  <= x"00000005";
	s_inAdd_Sub <= '0';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be $0C, s_oCo to be 0

    -- Test Case 3:
	s_iA  <= x"00000007";
	s_iB  <= x"00000005";
	s_inAdd_Sub <= '1';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be $02, s_oCo to be 0

    -- Test Case 4:
	s_iA  <= x"000000FE";
	s_iB  <= x"00000001";
	s_inAdd_Sub <= '1';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be $FD, s_oCo to be 0

    -- Test Case 5:
	s_iA  <= x"000000FE";
	s_iB  <= x"00000001";
	s_inAdd_Sub <= '0';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be $FF, s_oCo to be 0

    -- Test Case 6:
	s_iA  <= x"00000000";
	s_iB  <= x"00000001";
	s_inAdd_Sub <= '1';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be $FFFFFFFF, s_oCo to be 1

    -- Test Case 7:
	s_iA  <= x"FFFFFFFE";
	s_iB  <= x"00000001";
	s_inAdd_Sub <= '0';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be $FFFFFFFF, s_oCo to be 0

	wait;
end process;

end mixed;
