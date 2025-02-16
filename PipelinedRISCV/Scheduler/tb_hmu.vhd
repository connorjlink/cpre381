-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_hmu.vhd
-- DESCRIPTION: This file contains a testbench to verify the hmu.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O
use work.RISCV_types.all;

entity tb_hmu is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32);
end tb_hmu;

architecture mixed of tb_hmu is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal i_MaskStall    : std_logic;
signal i_InsnRS1      : std_logic_vector(4 downto 0);
signal i_InsnRS2      : std_logic_vector(4 downto 0);
signal i_DriverRS1    : std_logic_vector(4 downto 0);
signal i_DriverRS2    : std_logic_vector(4 downto 0);
signal i_DriverRD     : std_logic_vector(4 downto 0);
signal i_DriverIsLoad : std_logic; -- the instruction a load instruction (this could cause a read-after-write hazard)
signal i_ALURD        : std_logic_vector(4 downto 0);
signal i_ALUIsLoad    : std_logic;   
signal i_BranchMode   : natural;
signal i_Branch       : std_logic; -- indicate if the branch is taken or not (hooks to output of BGU)
signal i_IsBranch     : std_logic;
signal o_Break        : std_logic; -- stop the instruction pointer upcounter, will need to be ORed with the break signal off the driver!
signal o_InsnFlush    : std_logic;
signal o_InsnStall    : std_logic;
signal o_DriverFlush  : std_logic;
signal o_DriverStall  : std_logic;

begin

-- Instantiate the module under test
DUT0: entity work.hmu
	port MAP(
        i_CLK          => CLK,
        i_MaskStall    => i_MaskStall,
        i_InsnRS1      => i_InsnRS1, 
        i_InsnRS2      => i_InsnRS2, 
        i_DriverRS1    => i_DriverRS1, 
        i_DriverRS2    => i_DriverRS2, 
        i_DriverRD     => i_DriverRD, 
        i_DriverIsLoad => i_DriverIsLoad,
        i_ALURD        => i_ALURD, 
        i_ALUIsLoad    => i_ALUIsLoad,
        i_BranchMode   => i_BranchMode, 
        i_Branch       => i_Branch, 
        i_IsBranch     => i_IsBranch, 
        o_Break        => o_Break, 
        o_InsnFlush    => o_InsnFlush, 
        o_InsnStall    => o_InsnStall, 
        o_DriverFlush  => o_DriverFlush, 
        o_DriverStall  => o_DriverStall
    );

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
    wait for gCLK_HPER * 2;

    
    
	wait;
end process;

end mixed;
