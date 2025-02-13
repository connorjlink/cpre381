-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_RISCV_Processor.vhd
-- DESCRIPTION: This file contains a testbench to verify the tb_RISCV_Processor.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O
use work.RISCV_types.all;

entity tb_RISCV_Processor is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32);
end tb_RISCV_Processor;

architecture mixed of tb_RISCV_Processor is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component MIPS_Processor is
    generic(
        N : integer := work.RISCV_types.DATA_WIDTH
    );
    port(
        iCLK      : in std_logic;
        iRST      : in std_logic;
        iInstLd   : in std_logic;
        iInstAddr : in std_logic_vector(N-1 downto 0);
        iInstExt  : in std_logic_vector(N-1 downto 0);
        oALUOut   : out std_logic_vector(N-1 downto 0) -- TODO: Hook this up to the output of the ALU. It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.
    ); 
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

begin

-- Instantiate the module under test
DUT0: MIPS_Processor
	port MAP(
		iCLK      => CLK,
        iRST      => reset,
		iInstLd   => '0',
		iInstAddr => 32x"0",
		iInstExt  => 32x"0",
		oALUOut   => open
	);

-- This process resets the sequential components of the design.
-- It is held to be 1 across both the negative and positive edges of the clock
-- so it works regardless of whether the design uses synchronous (pos or neg edge)
-- or asynchronous resets.
P_RST: process
begin
	reset <= '1';
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

	wait;
end process;

end mixed;
