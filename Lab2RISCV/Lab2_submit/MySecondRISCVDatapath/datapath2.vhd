-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- datapath2.vhd
-- DESCRIPTION: This file contains an implementation of a slightly more advanced RISC-V-like datapath.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity datapath2 is
    port(i_CLK        : in  std_logic;
         i_RST        : in  std_logic;
         i_RD         : in  std_logic_vector(4 downto 0); -- write port
         i_RS1        : in  std_logic_vector(4 downto 0); -- read port 1
         i_RS2        : in  std_logic_vector(4 downto 0); -- read port 2
         i_Imm        : in  std_logic_vector(11 downto 0);
         i_nZero_Sign : in  std_logic;
         i_nAdd_Sub   : in  std_logic;
         i_ALUSrc     : in  std_logic; -- 0 = register, 1 = immediate
         i_RFSrc      : in  std_logic; -- 0 = ALU output, 1 = RAM output
         i_regWrite   : in  std_logic;
         i_memWrite   : in  std_logic;
         o_DS1        : out std_logic_vector(31 downto 0));
end datapath2;

architecture structural of datapath2 is

component mem is
    generic(DATA_WIDTH : natural := 32;
	        ADDR_WIDTH : natural := 10);
	port(clk  : in  std_logic;
         addr : in  std_logic_vector((ADDR_WIDTH-1) downto 0);
		 data : in  std_logic_vector((DATA_WIDTH-1) downto 0);
		 we	  : in  std_logic := '1';
		 q	  : out std_logic_vector((DATA_WIDTH -1) downto 0));
end component;

component mux2t1_N is
    generic(N : integer := 16);
    port(i_S  : in  std_logic;
         i_D0 : in  std_logic_vector(N-1 downto 0);
         i_D1 : in  std_logic_vector(N-1 downto 0);
         o_O  : out std_logic_vector(N-1 downto 0));
end component;

component ext is
    generic(IN_WIDTH  : integer := 12;
            OUT_WIDTH : integer := 32); 
    port(i_D          : in  std_logic_vector(IN_WIDTH-1 downto 0);
         i_nZero_Sign : in  std_logic;
         o_Q          : out std_logic_vector(OUT_WIDTH-1 downto 0));
end component;

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

-- Signal to hold the sign- or zero-extended immediate value
signal s_eImm : std_logic_vector(31 downto 0);

-- Signal to hold the computed ALU output
signal s_cALU : std_logic_vector(31 downto 0);
-- Signal to hold the shifted computed address
-- Necessary because the memory module we have is word-addressable, not byte-level
signal s_cAddr : std_logic_vector(31 downto 0);

-- Signal to hold the carry out
signal s_oCo : std_logic;

-- Signal to hold the output from memory to feed back to register file
signal s_eD : std_logic_vector(31 downto 0);

-- Signal to hold the selected register file data line
signal s_rfD : std_logic_vector(31 downto 0);

begin

    -- Attach an external read port for debugging
    o_DS1 <= s_DS1;

    g_RFSelector: mux2t1_N
        generic MAP(N => 32)
        port MAP(i_S  => i_RFSrc,
                 i_D0 => s_cALU,
                 i_D1 => s_eD,
                 o_O  => s_rfD);


    g_DatapathRegisterFile: regfile
        port MAP(i_CLK => i_CLK,
                 i_RST => i_RST,
                 i_RS1 => i_RS1,
                 i_RS2 => i_RS2,
                 i_RD  => i_RD,
                 i_WE  => i_regWrite,
                 i_D   => s_rfD,
                 o_DS1 => s_DS1,
                 o_DS2 => s_DS2);

    g_ALUExtender: ext
        generic MAP(IN_WIDTH  => 12,
                    OUT_WIDTH => 32)
        port MAP(i_D          => i_Imm,
                 i_nZero_Sign => i_nZero_Sign,
                 o_Q          => s_eImm);

    g_ALU: alu_addsub
        port MAP(i_A        => s_DS1,
                 i_B        => s_DS2,
                 i_Imm      => s_eImm,
                 i_ALUSrc   => i_ALUSrc,
                 i_nAdd_Sub => i_nAdd_Sub,
                 o_S        => s_cALU,
                 o_Co       => s_oCo);

    -- 2 bit shift since words are 2^2 = 4 bytes long
    s_cAddr <= std_logic_vector(shift_right(unsigned(s_cALU), 2));

    g_CPUMemory: mem
        port MAP(clk  => i_CLK,
                 addr => s_cAddr(9 downto 0), -- truncating address as the module is only 2**10 wide
                 data => s_DS2,
                 we   => i_memWrite,
                 q    => s_eD);
    
end structural;
