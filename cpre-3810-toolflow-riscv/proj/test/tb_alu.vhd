-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_alu.vhd
-- DESCRIPTION: This file contains an implementation of a simple testbench for the RISC-V ALU.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library std;
use std.env.all;
use std.textio.all;
use work.RISCV_types.all;

entity tb_alu is
    generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32);
end tb_alu;

architecture mixed of tb_alu is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component alu is
    generic(
        -- Data width in bits
        constant N : natural := 32
    );
    port(
        i_A     : in  std_logic_vector(31 downto 0);
        i_B     : in  std_logic_vector(31 downto 0);
        i_ALUOp : in  natural;
        o_F     : out std_logic_vector(31 downto 0);
        o_Co    : out std_logic
    );
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal s_iA : std_logic_vector(31 downto 0) := 32x"0";
signal s_iB : std_logic_vector(31 downto 0) := 32x"0";
signal s_iALUOp : natural := 0;
signal s_oF : std_logic_vector(31 downto 0) := 32x"0";
signal s_oCo : std_logic;

begin

-- Instantiate the module under test
DUTO: alu
    generic MAP(
        N => 32
    )
    port MAP(
        i_A     => s_iA,
        i_B     => s_iB,
        i_ALUOp => s_iALUOp,
        o_F     => s_oF,
        o_Co    => s_oCo
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

    -- Test Case 1
    s_iA <= 32x"5";
    s_iB <= 32x"7";
    s_iALUOp <= work.RISCV_types.ADD;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $C, s_oCo to be 0

    -- Test Case 2
    s_iA <= 32x"7";
    s_iB <= 32x"5";
    s_iALUOp <= work.RISCV_types.SUB;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $2, s_oCo to be 1 (not borrow)

    -- Test Case 3
    s_iA <= 32x"FFFFFFFF";
    s_iB <= 32x"CCCCCCCC";
    s_iALUOp <= work.RISCV_types.BAND;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $CCCCCCCC, s_oCo to be 0

    -- Test Case 4
    s_iA <= 32x"33333333";
    s_iB <= 32x"CCCCCCCC";
    s_iALUOp <= work.RISCV_types.BOR;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $FFFFFFFF, s_oCo to be 0

    -- Test Case 5
    s_iA <= 32x"33333333";
    s_iB <= 32x"FFFFFFFF";
    s_iALUOp <= work.RISCV_types.BXOR;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $CCCCCCCC, s_oCo to be 0

    -- Test Case 6
    s_iA <= 32x"80000000";
    s_iB <= 32x"1";
    s_iALUOp <= work.RISCV_types.BSLL;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $0, s_oCo to be 0

    -- Test Case 7
    s_iA <= 32x"80000000";
    s_iB <= 32x"1";
    s_iALUOp <= work.RISCV_types.BSRL;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $40000000, s_oCo to be 0

    -- Test Case 8
    s_iA <= 32x"80000000";
    s_iB <= 32x"1";
    s_iALUOp <= work.RISCV_types.BSRA;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $C0000000, s_oCo to be 0

    -- Test Case 9
    s_iA <= 32x"80000000";
    s_iB <= 32x"1";
    s_iALUOp <= work.RISCV_types.SLT;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $1, s_oCo to be 0

    -- Test Case 10
    s_iA <= 32x"80000000";
    s_iB <= 32x"1";
    s_iALUOp <= work.RISCV_types.SLTU;
    wait for gCLK_HPER * 2;
    -- Expect s_oF to be $0, s_oCo to be 0

    wait;
end process;

end mixed;
