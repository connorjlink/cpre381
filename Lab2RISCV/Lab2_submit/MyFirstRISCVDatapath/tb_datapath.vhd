-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_datapath.vhd
-- DESCRIPTION: This file contains a testbench to verify the datapath.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O
use work.my_types.all;

entity tb_datapath is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32);
end tb_datapath;

architecture mixed of tb_datapath is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component datapath is
    port(i_CLK        : in  std_logic;
         i_RST        : in  std_logic;
         i_D          : in  std_logic_vector(31 downto 0);
         i_Imm        : in  std_logic_vector(31 downto 0);
         i_RS1        : in  std_logic_vector(4 downto 0); -- read port 1
         i_RS2        : in  std_logic_vector(4 downto 0); -- read port 2
         i_RD         : in  std_logic_vector(4 downto 0); -- write port
         i_nAdd_Sub   : in  std_logic;
         i_ALUSrc     : in  std_logic;
         i_regWrite   : in  std_logic;
         o_Q          : out std_logic_vector(31 downto 0);
         o_Co         : out std_logic);
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal s_iImm        : std_logic_vector(31 downto 0) := 32x"0";
signal s_iRS1        : std_logic_vector(4 downto 0) := 5x"0";
signal s_iRS2        : std_logic_vector(4 downto 0) := 5x"0";
signal s_iRD         : std_logic_vector(4 downto 0) := 5x"0";
signal s_inAdd_Sub   : std_logic := '0';
signal s_iALUSrc     : std_logic := '0';
signal s_iregWrite   : std_logic := '0';
signal s_ioD         : std_logic_vector(31 downto 0); -- in/out, so not driven directly
signal s_oCo         : std_logic; -- [[maybe_unused]] 

begin

-- Instantiate the module under test
DUT0: datapath
	port MAP(i_CLK        => CLK,
             i_RST        => reset,
             i_D          => s_ioD,
             i_Imm        => s_iImm,
             i_RS1        => s_iRS1,
             i_RS2        => s_iRS2,
             i_RD         => s_iRD,
             i_nAdd_Sub   => s_inAdd_Sub,
             i_ALUSrc     => s_iALUSrc,
             i_regWrite   => s_iregWrite,
             o_Q          => s_ioD,
             o_Co         => s_oCo);

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

    -- addi x1, x0, 1 # Place “1” in x1
    s_iRD         <= 5x"1";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"1";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x2, x0, 2 # Place “2” in x2
    s_iRD         <= 5x"2";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"2";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x3, x0, 3 # Place “3” in x3
    s_iRD         <= 5x"3";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"3";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x4, x0, 4 # Place “4” in x4
    s_iRD         <= 5x"4";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"4";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x5, x0, 5 # Place “5” in x5
    s_iRD         <= 5x"5";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"5";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x6, x0, 6 # Place “6” in x6
    s_iRD         <= 5x"6";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"6";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x7, x0, 7 # Place “7” in x7
    s_iRD         <= 5x"7";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"7";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x8, x0, 8 # Place “8” in x8
    s_iRD         <= 5x"8";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"8";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x9, x0, 9 # Place “9” in x9
    s_iRD         <= 5x"9";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"9";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x10, x0, 10 # Place “10” in x10
    s_iRD         <= 5x"A";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"A";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- add x11, x1, x2 # x11 = x1 + x2
    s_iRD         <= 5x"B";
    s_iRS1        <= 5x"1";
    s_iRS2        <= 5x"2";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- sub x12, x11, x3 # x12 = x11 - x3
    s_iRD         <= 5x"C";
    s_iRS1        <= 5x"B";
    s_iRS2        <= 5x"3";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '1';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- add x13, x12, x4 # x13 = x12 + x4
    s_iRD         <= 5x"D";
    s_iRS1        <= 5x"C";
    s_iRS2        <= 5x"4";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- sub x14, x13, x5 # x14 = x13 - x5
    s_iRD         <= 5x"E";
    s_iRS1        <= 5x"D";
    s_iRS2        <= 5x"5";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '1';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- add x15, x14, x6 # x15 = x14 + x6
    s_iRD         <= 5x"F";
    s_iRS1        <= 5x"E";
    s_iRS2        <= 5x"6";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- sub x16, x15, x7 # x16 = x15 - x7
    s_iRD         <= 5x"10";
    s_iRS1        <= 5x"F";
    s_iRS2        <= 5x"7";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '1';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- add x17, x16, x8 # x17 = x16 + x8
    s_iRD         <= 5x"11";
    s_iRS1        <= 5x"10";
    s_iRS2        <= 5x"8";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- sub x18, x17, x9 # x18 = x17 - x9
    s_iRD         <= 5x"12";
    s_iRS1        <= 5x"11";
    s_iRS2        <= 5x"9";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '1';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- add x19, x18, x10 # x19 = x18 + x10
    s_iRD         <= 5x"13";
    s_iRS1        <= 5x"12";
    s_iRS2        <= 5x"A";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- addi x20, x0, -35 # Place “-35” in x20
    s_iRD         <= 5x"14";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"FDD";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- add x21, x19, x20 # x21 = x19 + x20
    s_iRD         <= 5x"15";
    s_iRS1        <= 5x"13";
    s_iRS2        <= 5x"14";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iregWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- test program complete, now read back all registers
    s_iRD         <= 5x"0";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 32x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iregWrite <= '0';
    wait for gCLK_HPER * 2;


    -- begin!
    s_iRS1 <= 5x"0";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"1";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"2";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"3";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"4";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"5";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"6";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"7";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"8";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"9";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"A";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"B";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"C";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"D";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"E";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"F";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"10";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"11";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"12";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"13";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"14";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"15";
    wait for gCLK_HPER * 2;

    s_iRS1 <= 5x"0";
    wait for gCLK_HPER * 2;


	wait;
end process;

end mixed;
