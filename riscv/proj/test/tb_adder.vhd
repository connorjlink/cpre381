-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_adder.vhd
-- DESCRIPTION: This file contains a testbench to verify the adder.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O

entity tb_adder is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 8);
end tb_adder;

architecture mixed of tb_adder is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component adder is
	port(i_A  : in  std_logic;
         i_B  : in  std_logic;
         i_Ci : in  std_logic;
	     o_S  : out std_logic;
         o_Co : out std_logic);
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal s_iA : std_logic := '0';
signal s_iB : std_logic := '0';
signal s_iCi : std_logic := '0';
signal s_oS : std_logic;
signal s_oCo : std_logic;

begin

-- Instantiate the module under test
DUT0: adder
	port MAP(i_A  => s_iA,
             i_B  => s_iB,
             i_Ci => s_iCi,
             o_S  => s_oS,
 		     o_Co => s_oCo);


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
	s_iA  <= '0';
	s_iB  <= '0';
	s_iCi <= '0';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be 0, s_oCo to be 0

	-- Test Case 2:
	s_iA  <= '0';
	s_iB  <= '0';
	s_iCi <= '1';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be 1, s_oCo to be 0

    -- Test Case 3:
	s_iA  <= '0';
	s_iB  <= '1';
	s_iCi <= '0';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be 1, s_oCo to be 0

    -- Test Case 4:
	s_iA  <= '0';
	s_iB  <= '1';
	s_iCi <= '1';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be 0, s_oCo to be 1

    -- Test Case 5:
	s_iA  <= '1';
	s_iB  <= '0';
	s_iCi <= '0';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be 1, s_oCo to be 0

    -- Test Case 6:
	s_iA  <= '1';
	s_iB  <= '0';
	s_iCi <= '1';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be 0, s_oCo to be 1

    -- Test Case 7:
	s_iA  <= '1';
	s_iB  <= '1';
	s_iCi <= '0';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be 0, s_oCo to be 1

    -- Test Case 7:
	s_iA  <= '1';
	s_iB  <= '1';
	s_iCi <= '1';
	wait for gCLK_HPER*2;
	-- Expect: s_oS to be 1, s_oCo to be 1

	wait;
end process;

end mixed;
