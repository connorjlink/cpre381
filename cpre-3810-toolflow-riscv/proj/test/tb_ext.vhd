-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_ext.vhd
-- DESCRIPTION: This file contains a testbench to verify the ext.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O

entity tb_ext is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 8);
end tb_ext;

architecture mixed of tb_ext is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component ext is
    generic(IN_WIDTH  : integer := 12;
            OUT_WIDTH : integer := 32);
	port(i_D          : in  std_logic_vector(IN_WIDTH-1 downto 0);
         i_nZero_Sign : in  std_logic;
         o_Q          : out std_logic_vector(OUT_WIDTH-1 downto 0));
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal s_iD          : std_logic_vector(11 downto 0) := b"000000000000";
signal s_inZero_Sign : std_logic := '0';
signal s_oQ          : std_logic_vector(31 downto 0);

begin

-- Instantiate the module under test
DUT0: ext
	port MAP(i_D          => s_iD,
             i_nZero_Sign => s_inZero_Sign,
             o_Q          => s_oQ);


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
    s_iD <= b"000000000000";
    s_inZero_Sign <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000000

    -- Test Case 2:
    s_iD <= b"000000000000";
    s_inZero_Sign <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000000

    -- Test Case 3:
    s_iD <= b"000000000111";
    s_inZero_Sign <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000007

    -- Test Case 4:
    s_iD <= b"000000000111";
    s_inZero_Sign <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000007

    -- Test Case 5:
    s_iD <= b"100000000111";
    s_inZero_Sign <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000407

    -- Test Case 6:
    s_iD <= b"100000000111";
    s_inZero_Sign <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFC07

    -- Test Case 7:
    s_iD <= b"100000000111";
    s_inZero_Sign <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $00000407

    -- Test Case 8:
    s_iD <= b"111111111111";
    s_inZero_Sign <= '0';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $000007FF

    -- Test Case 9:
    s_iD <= b"111111111111";
    s_inZero_Sign <= '1';
    wait for gCLK_HPER * 2;
    -- Expect: s_oQ to be $FFFFFFFF

	wait;
end process;

end mixed;
