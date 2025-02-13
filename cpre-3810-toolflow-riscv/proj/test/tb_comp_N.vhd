-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_comp_N.vhd
-- DESCRIPTION: This file contains a testbench to verify the comp_N.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O

entity tb_comp_N is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32);
end tb_comp_N;

architecture mixed of tb_comp_N is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component comp_N is
    generic(N : integer := 32);
	port(i_A : in  std_logic_vector(N-1 downto 0);
	     o_F : out std_logic_vector(N-1 downto 0));
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal s_iA : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00000000";
signal s_oF : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

-- Instantiate the module under test
DUT0: comp_N
    generic MAP(N => DATA_WIDTH)
	port MAP(i_A => s_iA,
		     o_F => s_oF);


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
	s_iA <= x"00000000";
	wait for gCLK_HPER*2;
	-- Expect: s_oF to be $FF...

	-- Test Case 2:
	s_iA <= x"FFFFFFFF";
	wait for gCLK_HPER*2;
	-- Expect: s_oF to be $00...

	-- Test Case 3:
	s_iA <= x"33333333";
	wait for gCLK_HPER*2;
	-- Expect: s_oF to be $CC...

	-- Test Case 4:
	s_iA <= x"88888888";
	wait for gCLK_HPER*2;
	-- Expect: s_oF to be $77...

	wait;
end process;

end mixed;
