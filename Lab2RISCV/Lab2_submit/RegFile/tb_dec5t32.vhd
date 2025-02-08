-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_dec5t32.vhd
-- DESCRIPTION: This file contains a testbench to verify the dec5t32.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O

entity tb_dec5t32 is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 8);
end tb_dec5t32;

architecture mixed of tb_dec5t32 is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component dec5t32 is
	port(i_S : in  std_logic_vector(4 downto 0);
         o_Q : out std_logic_vector(31 downto 0));
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal s_iS : std_logic_vector(4 downto 0) := b"00000";
signal s_oQ : std_logic_vector(31 downto 0);

begin

-- Instantiate the module under test
DUT0: dec5t32
	port MAP(i_S => s_iS,
             o_Q => s_oQ);


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
    s_iS <= "00000";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000000000000001
    
    -- Test Case 2:
    s_iS <= "00001";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000000000000010
    
    -- Test Case 3:
    s_iS <= "00010";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000000000000100
    
    -- Test Case 4:
    s_iS <= "00011";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000000000001000
    
    -- Test Case 5:
    s_iS <= "00100";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000000000010000
    
    -- Test Case 6:
    s_iS <= "00101";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000000000100000
    
    -- Test Case 7:
    s_iS <= "00110";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000000001000000
    
    -- Test Case 8:
    s_iS <= "00111";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000000010000000
    
    -- Test Case 9:
    s_iS <= "01000";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000000100000000
    
    -- Test Case 10:
    s_iS <= "01001";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000001000000000
    
    -- Test Case 11:
    s_iS <= "01010";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000010000000000
    
    -- Test Case 12:
    s_iS <= "01011";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000000100000000000
    
    -- Test Case 13:
    s_iS <= "01100";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000001000000000000
    
    -- Test Case 14:
    s_iS <= "01101";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000010000000000000
    
    -- Test Case 15:
    s_iS <= "01110";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000000100000000000000
    
    -- Test Case 16:
    s_iS <= "01111";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000001000000000000000
    
    -- Test Case 17:
    s_iS <= "10000";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000010000000000000000
    
    -- Test Case 18:
    s_iS <= "10001";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000000100000000000000000
    
    -- Test Case 19:
    s_iS <= "10010";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000001000000000000000000
    
    -- Test Case 20:
    s_iS <= "10011";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000010000000000000000000
    
    -- Test Case 21:
    s_iS <= "10100";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000000100000000000000000000
    
    -- Test Case 22:
    s_iS <= "10101";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000001000000000000000000000
    
    -- Test Case 23:
    s_iS <= "10110";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000010000000000000000000000
    
    -- Test Case 24:
    s_iS <= "10111";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000000100000000000000000000000
    
    -- Test Case 25:
    s_iS <= "11000";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000001000000000000000000000000
    
    -- Test Case 26:
    s_iS <= "11001";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000010000000000000000000000000
    
    -- Test Case 27:
    s_iS <= "11010";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00000100000000000000000000000000
    
    -- Test Case 28:
    s_iS <= "11011";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00001000000000000000000000000000
    
    -- Test Case 29:
    s_iS <= "11100";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00010000000000000000000000000000
    
    -- Test Case 30:
    s_iS <= "11101";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 00100000000000000000000000000000
    
    -- Test Case 31:
    s_iS <= "11110";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 01000000000000000000000000000000
    
    -- Test Case 32:
    s_iS <= "11111";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be 10000000000000000000000000000000

	wait;
end process;

end mixed;
