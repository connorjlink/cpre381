-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_cpu.vhd
-- DESCRIPTION: This file contains a testbench to verify the cpu.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O
use work.my_types.all;

entity tb_cpu is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32);
end tb_cpu;

architecture mixed of tb_cpu is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component cpu is
    port(i_CLK : in  std_logic;
         i_RST : in  std_logic);
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

begin

-- Instantiate the module under test
DUT0: cpu
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

	-- addi x25, x0, 0   # Expect: x25 = 0
	-- addi x26, x0, 256 # Expect: x26 = $100
	-- lw x1, 0(x25)     # Expect: x1 = $FFFFFFFF
	-- lw x2, 4(x25)     # Expect: x2 = $00000002
	-- add x1, x1, x2    # Expect: x1 = $00000001
	-- sw x1, 0(x26)     # Expect: mem[$100] = $00000001
	-- lw x2, 8(x25)     # Expect: x2 = $FFFFFFFD
	-- add x1, x1, x2    # Expect: x1 = $FFFFFFFE
	-- sw x1, 4(x26)     # Expect: mem[$101] = $FFFFFFFE
	-- lw x2, 12(x25)    # Expect: x2 = $00000004
	-- add x1, x1, x2    # Expect: x1 = $00000002
	-- sw x1, 8(x26)     # Expect: mem[$102] = $00000002
	-- lw x2, 16(x25)    # Expect: x2 = $00000005
	-- add x1, x1, x2    # Expect: x1 = $00000007
	-- sw x1, 12(x26)    # Expect: mem[$103] = $00000007
	-- lw x2, 20(x25)    # Expect: x2 = $00000006
	-- add x1, x1, x2    # Expect: x1 = $0000000D
	-- sw x1, 16(x26)    # Expect: mem[$104] = $0000000D
	-- lw x2, 24(x25)    # Expect: x2 = $FFFFFFF9
	-- add x1, x1, x2    # Expect: x1 = $00000006
	-- addi x27, x0, 512 # Expect: x27 = $200
	-- sw x1, -4(x27)    # Expect: mem[$199?] = $00000006
	-- nop 
    
	wait;
end process;

end mixed;
