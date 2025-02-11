-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- ram.vhd
-- DESCRIPTION: This file contains an implementation of a basic RISC-V RAM block.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.my_enums.all;

entity ram is
    generic(
        ADDR_WIDTH : natural := 10;
    );
    port(
        i_CLK        : in  std_logic;
        i_Addr       : in  std_logic_vector((ADDR_WIDTH-1) downto 0);
        i_Data       : in  std_logic_vector(31 downto 0);
        i_WE         : in  std_logic;
        i_nZero_Sign : in  std_logic;
        i_LSWidth    : in  natural;
        o_Q          : out std_logic_vector(31 downto 0);
    );
end bgu;

architecture mixed of ram is

component mem is
    generic 
    (
        DATA_WIDTH : natural := 32;
        ADDR_WIDTH : natural := 10
    );
    port 
    (
        clk  : in  std_logic;
        addr : in  std_logic_vector((ADDR_WIDTH-1) downto0);
        data : in  std_logic_vector((DATA_WIDTH-1) downto0);
        we   : in  std_logic := '1';
        q    : out std_logic_vector((DATA_WIDTH -1)downto 0)
    );
end component;

-- Corresponding to each load/store data width LSWidth
constant BYTE   : natural := 0;
constant HALF   : natural := 1;
constant WORD   : natural := 2;
constant DOUBLE : natural := 3;

begin

    
end mixed;
