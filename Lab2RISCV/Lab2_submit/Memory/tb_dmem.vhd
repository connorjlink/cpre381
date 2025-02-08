-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_dmem.vhd
-- DESCRIPTION: This file contains a testbench to verify the mem.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O

entity tb_dmem is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32;
            ADDR_WIDTH : integer := 10);
end tb_dmem;

architecture mixed of tb_dmem is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component mem is
    generic(DATA_WIDTH : natural := 32;
		    ADDR_WIDTH : natural := 10);
	port(clk  : in  std_logic;
		 addr : in  std_logic_vector((ADDR_WIDTH-1) downto 0);
		 data : in  std_logic_vector((DATA_WIDTH-1) downto 0);
		 we	  : in  std_logic := '1';
		 q	  : out std_logic_vector((DATA_WIDTH -1) downto 0));
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal s_iA  : std_logic_vector(9 downto 0) := b"0000000000";
signal s_iD  : std_logic_vector(31 downto 0) := x"00000000";
signal s_iWE : std_logic := '0';
signal s_oQ  : std_logic_vector(31 downto 0);

begin

-- Instantiate the module under test
dmem: mem
    generic MAP(DATA_WIDTH => DATA_WIDTH,
                ADDR_WIDTH => ADDR_WIDTH)
	port MAP(clk  => CLK,
             addr => s_iA,
             data => s_iD,
             we   => s_iWE,
             q    => s_oQ);


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

    -- 3c: ii.) read initial 10 values stored in memory
    -- Test Case 1:
    s_iA <= b"0000000000";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFFF

    -- Test Case 2:
    s_iA <= b"0000000001";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000002

    -- Test Case 3:
    s_iA <= b"0000000010";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFFD

    -- Test Case 4:
    s_iA <= b"0000000011";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000004

    -- Test Case 5:
    s_iA <= b"0000000100";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000005

    -- Test Case 6:
    s_iA <= b"0000000101";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000006

    -- Test Case 7:
    s_iA <= b"0000000110";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFF9

    -- Test Case 8:
    s_iA <= b"0000000111";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFF8

    -- Test Case 9:
    s_iA <= b"0000001000";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000009

    -- Test Case 10:
    s_iA <= b"0000001001";
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFF6


    -- 3c: iii.) write back values consecutively starting at $100
    -- Test Case 11:
    s_iA  <= b"0100000000";
    s_iD  <= x"FFFFFFFF";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFFF

    -- Test Case 12:
    s_iA  <= b"0100000001";
    s_iD  <= x"00000002";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000002

    -- Test Case 13:
    s_iA  <= b"0100000010";
    s_iD  <= x"FFFFFFFD";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFFD

    -- Test Case 14:
    s_iA  <= b"0100000011";
    s_iD  <= x"00000004";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000004

    -- Test Case 15:
    s_iA  <= b"0100000100";
    s_iD  <= x"00000005";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000005

    -- Test Case 16:
    s_iA  <= b"0100000101";
    s_iD  <= x"00000006";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000006

    -- Test Case 17:
    s_iA  <= b"0100000110";
    s_iD  <= x"FFFFFFF9";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFF9

    -- Test Case 18:
    s_iA  <= b"0100000111";
    s_iD  <= x"FFFFFFF8";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFF8

    -- Test Case 19:
    s_iA  <= b"0100001000";
    s_iD  <= x"00000009";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000009

    -- Test Case 20:
    s_iA  <= b"0100001001";
    s_iD  <= x"FFFFFFF6";
    s_iWE <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFF6


    -- 3c: iv.) read back values consecutively starting at $100
    -- Test Case 21:
    s_iA <= b"0100000000";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFFF

    -- Test Case 22:
    s_iA <= b"0100000001";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000002

    -- Test Case 23:
    s_iA <= b"0100000010";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFFD

    -- Test Case 24:
    s_iA <= b"0100000011";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000004

    -- Test Case 25:
    s_iA <= b"0100000100";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000005

    -- Test Case 26:
    s_iA <= b"0100000101";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000006

    -- Test Case 27:
    s_iA <= b"0100000110";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFF9

    -- Test Case 28:
    s_iA <= b"0100000111";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFF8

    -- Test Case 29:
    s_iA <= b"0100001000";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000009

    -- Test Case 30:
    s_iA <= b"0100001001";
    s_iWE <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFF6

	wait;
end process;

end mixed;
