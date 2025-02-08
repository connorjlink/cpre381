-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- datapath.vhd
-- DESCRIPTION: This file contains an implementation of a simple RISC-V datapath.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity datapath is
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
end datapath;

architecture structural of datapath is

component alu_addsub is
    generic(N : integer := 32);
    port(i_A        : in  std_logic_vector(N-1 downto 0);
         i_B        : in  std_logic_vector(N-1 downto 0);
         i_Imm      : in  std_logic_vector(N-1 downto 0);
         i_ALUSrc   : in  std_logic;
         i_nAdd_Sub : in  std_logic;
         o_S        : out std_logic_vector(N-1 downto 0);
         o_Co       : out std_logic);
end component;

component regfile is
    port(i_CLK : in  std_logic;
         i_RST : in  std_logic;
         i_RS1 : in  std_logic_vector(4 downto 0);
         i_RS2 : in  std_logic_vector(4 downto 0);
         i_RD  : in  std_logic_vector(4 downto 0);
         i_WE  : in  std_logic;
         i_D   : in  std_logic_vector(31 downto 0);
         o_DS1 : out std_logic_vector(31 downto 0);
         o_DS2 : out std_logic_vector(31 downto 0));
end component;

-- Signals to hold the intermediate outputs from the register file
signal s_DS1 : std_logic_vector(31 downto 0);
signal s_DS2 : std_logic_vector(31 downto 0);

begin

    g_RegisterFile: regfile
        port MAP(i_CLK => i_CLK,
                 i_RST => i_RST,
                 i_RS1 => i_RS1,
                 i_RS2 => i_RS2,
                 i_RD  => i_RD,
                 i_WE  => i_regWrite,
                 i_D   => i_D,
                 o_DS1 => s_DS1,
                 o_DS2 => s_DS2);

    g_ALUAddSub: alu_addsub
        port MAP(i_A        => s_DS1,
                 i_B        => s_DS2,
                 i_Imm      => i_Imm,
                 i_ALUSrc   => i_ALUSrc,
                 i_nAdd_Sub => i_nAdd_Sub,
                 o_S        => o_Q,
                 o_Co       => o_Co);
    
end structural;
