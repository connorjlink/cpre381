-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- cpu.vhd
-- DESCRIPTION: This file contains an implementation of a basic RISC-V core.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_enums.all;

entity cpu is
    port(i_CLK : in std_logic;
         i_RST : in std_logic);
end cpu;

architecture mixed of cpu is

component driver is
    port(
        i_CLK       : in  std_logic;
        i_RST       : in  std_logic;
        i_Insn      : in  std_logic_vector(31 downto 0);
        i_Branch    : in  std_logic;
        o_MemWrite  : out std_logic;
        o_RegWrite  : out std_logic;
        o_RFSrc     : out std_logic; -- 0 = ALU, 1 = registers
        o_ALUSrc    : out std_logic; -- 0 = immediate, 1 = register
        o_ALUOp     : out natural;
        o_BGUOp     : out natural;
        o_LSWidth   : out natural;
        o_RD        : out std_logic_vector(4 downto 0);
        o_RS1       : out std_logic_vector(4 downto 0);
        o_RS2       : out std_logic_vector(4 downto 0);
        o_Imm       : out std_logic_vector(31 downto 0);
        o_iAddr     : out std_logic_vector(31 downto 0);
        o_Break     : out std_logic
    );
end component;

component alu is
    port(
        i_A     : in  std_logic_vector(31 downto 0);
        i_B     : in  std_logic_vector(31 downto 0);
        i_ALUOp : in  natural;
        o_F     : out std_logic_vector(31 downto 0);
        o_Co    : out std_logic
    );
end component;

component mem is
    generic(DATA_WIDTH : natural := 32;
	        ADDR_WIDTH : natural := 10);
	port(
        clk  : in  std_logic;
        addr : in  std_logic_vector((ADDR_WIDTH-1) downto 0);
		data : in  std_logic_vector((DATA_WIDTH-1) downto 0);
		we	 : in  std_logic := '1';
		q	 : out std_logic_vector((DATA_WIDTH -1) downto 0)
    );
end component;

component ext is
    generic(
        IN_WIDTH  : integer := 12;
        OUT_WIDTH : integer := 32
    ); 
    port(
        i_D          : in  std_logic_vector(IN_WIDTH-1 downto 0);
        i_nZero_Sign : in  std_logic;
        o_Q          : out std_logic_vector(OUT_WIDTH-1 downto 0)
    );
end component;

component bgu is 
    port(
        i_CLK    : in  std_logic;
        i_DS1    : in  std_logic_vector(31 downto 0);
        i_DS2    : in  std_logic_vector(31 downto 0);
        i_BGUOp  : in  natural;
        o_Branch : out std_logic 
    );
end component;

component regfile is
    port(
        i_CLK : in  std_logic;
        i_RST : in  std_logic;
        i_RS1 : in  std_logic_vector(4 downto 0);
        i_RS2 : in  std_logic_vector(4 downto 0);
        i_RD  : in  std_logic_vector(4 downto 0);
        i_WE  : in  std_logic;
        i_D   : in  std_logic_vector(31 downto 0);
        o_DS1 : out std_logic_vector(31 downto 0);
        o_DS2 : out std_logic_vector(31 downto 0)
    );
end component;

-- Signals to hold memory inputs and outputs
signal s_mInsn : std_logic_vector(31 downto 0);
signal s_mData : std_logic_vector(31 downto 0);

-- Signals to hold the intermediate outputs from the register file
signal s_DS1 : std_logic_vector(31 downto 0);
signal s_DS2 : std_logic_vector(31 downto 0);

-- Signal to hold the sign- or zero-extended immediate value
signal s_eImm : std_logic_vector(31 downto 0);

-- Signal to hold the ALU inputs and outputs
signal s_aluB : std_logic_vector(31 downto 0);
signal s_aluF : std_logic_vector(31 downto 0);
signal s_oCo : std_logic;

-- Signal to hold the register file inputs and outputs
signal s_rfD : std_logic_vector(31 downto 0);

-- Signals to hold the control lines from the driver
signal s_dMemWrite : std_logic;
signal s_dRegWrite : std_logic;
signal s_dRFSrc    : std_logic;
signal s_dALUSrc   : std_logic;
signal s_dALUOp    : natural;
signal s_dBGUOp    : natural;
signal s_dLSWidth  : natural;
signal s_dRD       : std_logic_vector(4 downto 0);
signal s_dRS1      : std_logic_vector(4 downto 0);
signal s_dRS2      : std_logic_vector(4 downto 0);
signal s_dImm      : std_logic_vector(31 downto 0);
signal s_iAddr     : std_logic_vector(31 downto 0);
signal s_Break     : std_logic;
signal s_dAddr     : std_logic_vector(31 downto 0);

-- Signals to handle the output of the BGU
signal s_Branch : std_logic;

-- Signal to handle the shifted addresses
signal s_iAddrShift : std_logic_vector(9 downto 0);
signal s_dAddrShift : std_logic_vector(9 downto 0);

-- Signal to hold the negated clock
signal s_nCLK : std_logic;

begin

    s_nCLK <= not i_CLK;

    g_CPUBranchUnit: bgu
        port MAP(
            i_CLK => i_CLK,
            i_DS1 => s_DS1,
            i_DS2 => s_DS2,
            i_BGUOp => s_dBGUOp,
            o_Branch => s_Branch
        );

    s_iAddrShift(9 downto 0) <= s_iAddr(11 downto 2);
    s_dAddrShift(9 downto 0) <= s_dAddr(11 downto 2);

    g_CPUInstructionMemory: mem
        generic MAP(
            DATA_WIDTH => 32,
            ADDR_WIDTH => 10
        )
        port MAP(
            -- TODO: should this be posedge or negedge
            clk  => i_CLK,
            addr => s_iAddrShift,
            data => 32x"0", -- treated as read only memory
            we   => '0',
            q    => s_mInsn
        );

    g_CPUDataMemory: mem
        generic MAP(
            DATA_WIDTH => 32,
            ADDR_WIDTH => 10
        )
        port MAP(
            -- TODO: should this be posedge or negedge
            -- clk  => i_CLK, 
            clk => s_nCLK,
            addr => s_dAddrShift,
            data => s_DS2,
            we   => s_dMemWrite,
            q    => s_mData
        );

    g_CPUDriver: driver
        port MAP(
            i_CLK       => i_CLK,
            i_RST       => i_RST,
            i_Insn      => s_mInsn,
            i_Branch    => s_Branch,
            o_MemWrite  => s_dMemWrite,
            o_RegWrite  => s_dRegWrite,
            o_RFSrc     => s_dRFSrc,
            o_ALUSrc    => s_dALUSrc,
            o_ALUOp     => s_dALUOp,
            o_BGUOp     => s_dBGUOp,
            o_LSWidth   => s_dLSWidth,
            o_RD        => s_dRD,
            o_RS1       => s_dRS1,
            o_RS2       => s_dRS2, 
            o_Imm       => s_dImm,
            o_iAddr     => s_iAddr,
            o_Break     => s_Break
        );

    s_dAddr <= s_aluF;

    s_rfD <= s_mData when (s_dRFSrc = '1') else
             s_aluF;

    g_CPURegisterFile: regfile
        port MAP(
            i_CLK => s_nCLK,
            --i_CLK => i_CLK,
            i_RST => i_RST,
            i_RS1 => s_dRS1,
            i_RS2 => s_dRS2,
            i_RD  => s_dRD,
            i_WE  => s_dRegWrite,
            i_D   => s_rfD,
            o_DS1 => s_DS1,
            o_DS2 => s_DS2
        );

    s_aluB <= s_DS2 when (s_dALUSrc = '0') else
              s_dImm;

    g_CPUALU: alu
        port MAP(
            i_A     => s_DS1,
            i_B     => s_aluB,
            i_ALUOp => s_dALUOp,
            o_F     => s_aluF,
            o_Co    => s_oCo
        );

end mixed;
