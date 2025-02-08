-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- tb_datapath2.vhd
-- DESCRIPTION: This file contains a testbench to verify the datapath2.vhd module.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O
use work.my_types.all;

entity tb_datapath2 is
	generic(gCLK_HPER  : time := 10 ns;
     	    DATA_WIDTH : integer := 32);
end tb_datapath2;

architecture mixed of tb_datapath2 is

-- Total clock period
constant cCLK_PER : time := gCLK_HPER * 2;

-- Element under test
component datapath2 is
    port(i_CLK        : in  std_logic;
         i_RST        : in  std_logic;
         i_Imm        : in  std_logic_vector(11 downto 0);
         i_RS1        : in  std_logic_vector(4 downto 0); -- read port 1
         i_RS2        : in  std_logic_vector(4 downto 0); -- read port 2
         i_RD         : in  std_logic_vector(4 downto 0); -- write port
         i_nZero_Sign : in  std_logic;
         i_nAdd_Sub   : in  std_logic;
         i_ALUSrc     : in  std_logic;
         i_RFSrc      : in  std_logic; -- 0 = ALU output, 1 = RAM output
         i_regWrite   : in  std_logic;
         i_memWrite   : in  std_logic;
         o_DS1        : out std_logic_vector(31 downto 0));
end component;

-- Create helper signals
signal CLK, reset : std_logic := '0';

-- Create input and output signals for the module under test
signal s_iImm        : std_logic_vector(11 downto 0) := 12x"0";
signal s_iRS1        : std_logic_vector(4 downto 0) := 5x"0";
signal s_iRS2        : std_logic_vector(4 downto 0) := 5x"0";
signal s_iRD         : std_logic_vector(4 downto 0) := 5x"0";
signal s_inZero_Sign : std_logic := '0';
signal s_inAdd_Sub   : std_logic := '0';
signal s_iALUSrc     : std_logic := '0';
signal s_iRFSrc      : std_logic := '0';
signal s_iregWrite   : std_logic := '0';
signal s_imemWrite   : std_logic := '0';
signal s_oDS1        : std_logic_vector(31 downto 0);

begin

-- Instantiate the module under test
DUT0: datapath2
	port MAP(i_CLK        => CLK,
             i_RST        => reset,
             i_Imm        => s_iImm,
             i_RS1        => s_iRS1,
             i_RS2        => s_iRS2,
             i_RD         => s_iRD,
             i_nZero_Sign => s_inZero_Sign,
             i_nAdd_Sub   => s_inAdd_Sub,
             i_ALUSrc     => s_iALUSrc,
             i_RFSrc      => s_iRFSrc,
             i_regWrite   => s_iregWrite,
             i_memWrite   => s_imemWrite,
             o_DS1        => s_oDS1);

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

    -- RISC-V effectively always uses sign extension per the documentation
    s_inZero_Sign <= '1';


    -- addi x25, x0, 0   # Load &A into x25
    s_iRD         <= 5x"19";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '0';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- addi x26, x0, 256 # Load &B into x26
    s_iRD         <= 5x"1A";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"100";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '0';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- lw x1, 0(x25)     # Load A[0] into x1
    s_iRD         <= 5x"1";
    s_iRS1        <= 5x"19";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- lw x2, 4(x25)     # Load A[1] into x2
    s_iRD         <= 5x"2";
    s_iRS1        <= 5x"19";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"4";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- add x1, x1, x2    # x1 = x1 + x2
    s_iRD         <= 5x"1";
    s_iRS1        <= 5x"1";
    s_iRS2        <= 5x"2";
    s_iImm        <= 12x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iRFSrc      <= '0';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- sw x1, 0(x26)     # Store x1 into B[0]
    s_iRD         <= 5x"0";
    s_iRS1        <= 5x"1A";
    s_iRS2        <= 5x"1";
    s_iImm        <= 12x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '0';
    s_imemWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- lw x2, 8(x25)     # Load A[2] into x2
    s_iRD         <= 5x"2";
    s_iRS1        <= 5x"19";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"8";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- add x1, x1, x2    # x1 = x1 + x2
    s_iRD         <= 5x"1";
    s_iRS1        <= 5x"1";
    s_iRS2        <= 5x"2";
    s_iImm        <= 12x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iRFSrc      <= '0';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- sw x1, 4(x26)     # Store x1 into B[1]
    s_iRD         <= 5x"0";
    s_iRS1        <= 5x"1A";
    s_iRS2        <= 5x"1";
    s_iImm        <= 12x"4";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '0';
    s_imemWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- lw x2, 12(x25)    # Load A[3] into x2
    s_iRD         <= 5x"2";
    s_iRS1        <= 5x"19";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"C";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- add x1, x1, x2    # x1 = x1 + x2
    s_iRD         <= 5x"1";
    s_iRS1        <= 5x"1";
    s_iRS2        <= 5x"2";
    s_iImm        <= 12x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iRFSrc      <= '0';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- sw x1, 8(x26)     # Store x1 into B[2]
    s_iRD         <= 5x"0";
    s_iRS1        <= 5x"1A";
    s_iRS2        <= 5x"1";
    s_iImm        <= 12x"8";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '0';
    s_imemWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- lw x2, 16(x25)    # Load A[4] into x2
    s_iRD         <= 5x"2";
    s_iRS1        <= 5x"19";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"10";
    s_inZero_Sign <= '0';
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- add x1, x1, x2    # x1 = x1 + x2
    s_iRD         <= 5x"1";
    s_iRS1        <= 5x"1";
    s_iRS2        <= 5x"2";
    s_iImm        <= 12x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iRFSrc      <= '0';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- sw x1, 12(x26)    # Store x1 into B[3]
    s_iRD         <= 5x"0";
    s_iRS1        <= 5x"1A";
    s_iRS2        <= 5x"1";
    s_iImm        <= 12x"C";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '0';
    s_imemWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- lw x2, 20(x25)    # Load A[5] into x2
    s_iRD         <= 5x"2";
    s_iRS1        <= 5x"19";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"14";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- add x1, x1, x2    # x1 = x1 + x2
    s_iRD         <= 5x"1";
    s_iRS1        <= 5x"1";
    s_iRS2        <= 5x"2";
    s_iImm        <= 12x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iRFSrc      <= '0';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- sw x1, 16(x26)    # Store x1 into B[4]
    s_iRD         <= 5x"0";
    s_iRS1        <= 5x"1A";
    s_iRS2        <= 5x"1";
    s_iImm        <= 12x"10";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '0';
    s_imemWrite   <= '1';
    wait for gCLK_HPER * 2;

    -- lw x2, 24(x25)    # Load A[6] into x2
    s_iRD         <= 5x"2";
    s_iRS1        <= 5x"19";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"18";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- add x1, x1, x2    # x1 = x1 + x2
    s_iRD         <= 5x"1";
    s_iRS1        <= 5x"1";
    s_iRS2        <= 5x"2";
    s_iImm        <= 12x"0";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '0';
    s_iRFSrc      <= '0';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- addi x27, x0, 512 # Load &B[64] into x27
    s_iRD         <= 5x"1B";
    s_iRS1        <= 5x"0";
    s_iRS2        <= 5x"0";
    s_iImm        <= 12x"200";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '0';
    s_iregWrite   <= '1';
    s_imemWrite   <= '0';
    wait for gCLK_HPER * 2;

    -- sw x1, -4(x27)    # Store x1 into B[63]
    s_iRD         <= 5x"0";
    s_iRS1        <= 5x"1B";
    s_iRS2        <= 5x"1";
    s_iImm        <= 12x"FFC";
    s_inAdd_Sub   <= '0';
    s_iALUSrc     <= '1';
    s_iRFSrc      <= '1';
    s_iregWrite   <= '0';
    s_imemWrite   <= '1';
    wait for gCLK_HPER * 2;


	wait;
end process;

end mixed;
