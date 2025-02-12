-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_software_cpu.vhd
-- DESCRIPTION: This file contains a testbench to verify the software_cpu.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O
use work.RISCV_types.all;
use work.RISCV_types.all;
use work.my_records.all;

entity tb_software_cpu is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32);
end tb_software_cpu;

architecture mixed of tb_software_cpu is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component software_cpu is
    port(i_CLK : in  std_logic;
         i_RST : in  std_logic);
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

begin

-- Instantiate the module under test
DUT0: software_cpu
	port MAP(i_CLK => CLK,
             i_RST => reset);

-- This process resets the sequential components of the design.
-- It is held to be 1 across both the negative and positive edges of the clock
-- so it works regardless of whether the design uses synchronous (pos or neg edge)
-- or asynchronous resets.
P_RST: process
begin
	reset <= '1';
	wait for gCLK_HPER*2;
	wait for gCLK_HPER*2;
	wait for gCLK_HPER/2; -- don't change inputs on clock edges
	reset <= '0';
	wait;
end process;  

--This first process is to setup the clock for the test bench
P_CLK: process
begin
	CLK <= '1';         -- clock starts at 1
	wait for gCLK_HPER; -- after half a cycle
	CLK <= '0';         -- clock becomes a 0 (negative edge)
	wait for gCLK_HPER; -- after half a cycle, process begins evaluation again
end process;


-- Assign inputs 
P_TEST_CASES: process
begin
	wait for gCLK_HPER;
	wait for gCLK_HPER/2; -- don't change inputs on clock edges
    wait for gCLK_HPER * 2;

    -- running loaded hex binary image
    
	wait;
end process;

end mixed;
