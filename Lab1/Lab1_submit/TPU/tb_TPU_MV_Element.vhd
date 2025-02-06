-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- tb_TPU_MV_Element.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a testbench for the TPU MAC unit.
--              
-- 01/03/2020 by H3::Design created.
-- 01/16/2025 by CWS::Switched from integer to std_logic_vector.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- For logic types I/O
library std;
use std.env.all;                -- For hierarchical/external signals
use std.textio.all;             -- For basic I/O

-- Usually name your testbench similar to below for clarity tb_<name>
-- TODO: change all instances of tb_TPU_MV_Element to reflect the new testbench.
entity tb_TPU_MV_Element is
  generic(gCLK_HPER   : time := 10 ns;
          DATA_WIDTH  : integer := 8);   -- Generic for half of the clock cycle period
end tb_TPU_MV_Element;

architecture mixed of tb_TPU_MV_Element is

-- Define the total clock period time
constant cCLK_PER  : time := gCLK_HPER * 2;

-- We will be instantiating our design under test (DUT), so we need to specify its
-- component interface.
-- TODO: change component declaration as needed.
component TPU_MV_Element is
  generic(WIDTH : integer := 8);
  port(iCLK           : in std_logic;
    iX 		            : in std_logic_vector(WIDTH-1 downto 0);
    iW 		            : in std_logic_vector(WIDTH-1 downto 0);
    iLdW 		          : in std_logic;
    iY                : in std_logic_vector(WIDTH-1 downto 0);
    oY 		            : out std_logic_vector(4*WIDTH-1 downto 0);
    oX 		            : out std_logic_vector(WIDTH-1 downto 0));
end component;

-- Create signals for all of the inputs and outputs of the file that you are testing
-- := '0' or := (others => '0') just make all the signals start at an initial value of zero
signal CLK, reset : std_logic := '0';

-- TODO: change input and output signals as needed.
signal s_iX   : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00";
signal s_iW   : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00";
signal s_iLdW : std_logic := '0';
signal s_iY   : std_logic_vector(DATA_WIDTH-1 downto 0) := x"00";
signal s_oY   : std_logic_vector(4*DATA_WIDTH-1 downto 0);
signal s_oX   : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  -- TODO: Actually instantiate the component to test and wire all signals to the corresponding
  -- input or output. Note that DUT0 is just the name of the instance that can be seen 
  -- during simulation. What follows DUT0 is the entity name that will be used to find
  -- the appropriate library component during simulation loading.
  DUT0: TPU_MV_Element
  generic map (WIDTH => DATA_WIDTH)
  port map(
            iCLK     => CLK,
            iX       => s_iX,
            iW       => s_iW,
            iLdW     => s_iLdW,
            iY       => s_iY,
            oY       => s_oY,
            oX       => s_oX);
  --You can also do the above port map in one line using the below format: http://www.ics.uci.edu/~jmoorkan/vhdlref/compinst.html

  
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
  
  -- Assign inputs for each test case.
  -- TODO: add test cases as needed.
  P_TEST_CASES: process
  begin
    wait for gCLK_HPER;
    wait for gCLK_HPER/2; -- for waveform clarity, I prefer not to change inputs on clk edges

    -- Test case 1:
    -- Initialize weight value to 10.
    s_iX   <= x"00";  -- Not strictly necessary, but this makes the testcases easier to read
    s_iW   <= x"0A";  -- 10 in hexadecimal
    s_iLdW <= '1';
    s_iY   <= x"00";  -- Not strictly necessary, but this makes the testcases easier to read
    wait for gCLK_HPER*2;
    -- Expect: s_W internal signal to be 10 after positive edge of clock

    -- Test case 2:
    -- Perform average example of an input activation of 3 and a partial sum of 25. The weight is still 10. 
    s_iX   <= x"03";  -- 3 in hexadecimal  
    s_iW   <= x"00";  -- Not strictly necessary, but this makes the testcases easier to read
    s_iLdW <= '0';    -- Make sure we don't continue to load.
    s_iY   <= x"19";  -- 25 in hexadecimal
    wait for gCLK_HPER*2;
    wait for gCLK_HPER*2;
    -- Expect: o_Y output signal to be 55 = 3*10+25 and o_X output signal to be 3 after two positive edge of clock.

    -- TODO: add test cases as needed (at least 3 more for this lab)


    wait;
  end process;

end mixed;
