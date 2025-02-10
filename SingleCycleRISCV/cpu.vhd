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
        i_CLK        : in  std_logic;
        i_RST        : in  std_logic;
        i_Insn       : in  std_logic_vector(31 downto 0);
        i_MaskStall  : in  std_logic;
        o_MemWrite   : out std_logic;
        o_RegWrite   : out std_logic;
        o_RFSrc      : out natural; -- 0 = memory, 1 = ALU, 2 = IP+4
        o_ALUSrc     : out std_logic; -- 0 = register, 1 = immediate
        o_ALUOp      : out natural;
        o_BGUOp      : out natural;
        o_LSWidth    : out natural;
        o_RD         : out std_logic_vector(4 downto 0);
        o_RS1        : out std_logic_vector(4 downto 0);
        o_RS2        : out std_logic_vector(4 downto 0);
        o_Imm        : out std_logic_vector(31 downto 0);
        o_BranchMode : out natural;
        o_Break      : out std_logic;
        o_IsBranch   : out std_logic;
        o_nInc2_Inc4 : out std_logic;
        o_IPToALU    : out std_logic
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

component ip is
    generic(
        -- Signal to hold the default data page address (according to RARS at least)
        ResetAddress : std_logic_vector(31 downto 0) := 32x"00400000"
    );
    port(
        i_CLK        : in  std_logic;
        i_RST        : in  std_logic;
        i_Load       : in  std_logic;
        i_Addr       : in  std_logic_vector(31 downto 0);
        i_nInc2_Inc4 : in  std_logic; -- 0 = inc2, 1 = inc4
        i_Stall      : in  std_logic;
        o_Addr       : out std_logic_vector(31 downto 0);
        o_LinkAddr   : out std_logic_vector(31 downto 0)
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
signal s_aluA : std_logic_vector(31 downto 0);
signal s_aluB : std_logic_vector(31 downto 0);
signal s_aluF : std_logic_vector(31 downto 0);
signal s_oCo : std_logic;

-- Signal to hold the register file inputs and outputs
signal s_rfD : std_logic_vector(31 downto 0);

-- Signals to hold the control lines from the driver
signal s_dMemWrite   : std_logic;
signal s_dRegWrite   : std_logic;
signal s_dRFSrc      : natural; -- 0 = ALU, 1 = memory, 2 = IP+4
signal s_dALUSrc     : std_logic;
signal s_dALUOp      : natural;
signal s_dBGUOp      : natural;
signal s_dLSWidth    : natural;
signal s_dRD         : std_logic_vector(4 downto 0);
signal s_dRS1        : std_logic_vector(4 downto 0);
signal s_dRS2        : std_logic_vector(4 downto 0);
signal s_dImm        : std_logic_vector(31 downto 0);
signal s_dBranchMode : natural;
signal s_dBreak      : std_logic;
signal s_dIPToALU    : std_logic;

-- Signals to handle the output of the BGU
signal s_Branch : std_logic;

-- Signal to hold the current instruction pointer
signal s_ipAddr : std_logic_vector(31 downto 0);

-- Signals to hold the data memory address pointer
signal s_dAddr : std_logic_vector(31 downto 0);

-- Signal to handle the shifted addresses
signal s_ipAddrShift : std_logic_vector(9 downto 0);
signal s_dAddrShift : std_logic_vector(9 downto 0);

-- Signal to hold the modified clock
signal s_gCLK  : std_logic;
signal s_ngCLK : std_logic;

-- Signals to hold the computed memory instruction address input to the IP
signal s_effectiveAddr : std_logic_vector(31 downto 0);
signal s_linkAddr      : std_logic_vector(31 downto 0);

-- is the current instruction two or four bytes long?
signal s_dnInc2_Inc4 : std_logic; 

begin

    s_effectiveAddr <= std_logic_vector(signed(s_ipAddr) + signed(s_dImm)) when (s_dBranchMode = work.my_enums.JAL)  else
                       std_logic_vector(signed(s_DS1) + signed(s_dImm))    when (s_dBranchMode = work.my_enums.JALR) else 
                       std_logic_vector(signed(s_ipAddr) + signed(s_dImm)) when (s_dBranchMode = work.my_enums.BCC)  else
                       32x"0";
                       
    g_InstructionPointerUnit: ip
        generic MAP(
            ResetAddress => 32x"0"
        )
        port MAP(
            i_CLK        => i_CLK,
            i_RST        => i_RST,
            i_Load       => s_Branch,
            i_Addr       => s_effectiveAddr,
            i_nInc2_Inc4 => s_dnInc2_Inc4,
            --i_Stall      => s_dBreak, -- only relevant for pipelined CPU model
            i_Stall      => '0',
            o_Addr       => s_ipAddr,
            o_LinkAddr   => s_linkAddr
        );

    s_gCLK <= (not s_dBreak) and i_CLK;
    s_ngCLK <= not s_gCLK;

    g_CPUBranchUnit: bgu
        port MAP(
            i_CLK => s_gCLK,
            i_DS1 => s_DS1,
            i_DS2 => s_DS2,
            i_BGUOp => s_dBGUOp,
            o_Branch => s_Branch
        );

    s_ipAddrShift(9 downto 0) <= s_ipAddr(11 downto 2);
    s_dAddrShift(9 downto 0) <= s_dAddr(11 downto 2);

    g_CPUInstructionMemory: mem
        generic MAP(
            DATA_WIDTH => 32,
            ADDR_WIDTH => 10
        )
        port MAP(
            -- TODO: should this be posedge or negedge
            clk  => s_gCLK,
            addr => s_ipAddrShift,
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
            -- clk  => s_gCLK, 
            clk => s_gCLK,
            addr => s_dAddrShift,
            data => s_DS2,
            we   => s_dMemWrite,
            q    => s_mData
        );

    g_CPUDriver: driver
        port MAP(
            i_CLK        => s_gCLK,
            i_RST        => i_RST,
            i_Insn       => s_mInsn,
            i_MaskStall  => '0',
            o_MemWrite   => s_dMemWrite,
            o_RegWrite   => s_dRegWrite,
            o_RFSrc      => s_dRFSrc,
            o_ALUSrc     => s_dALUSrc,
            o_ALUOp      => s_dALUOp,
            o_BGUOp      => s_dBGUOp,
            o_LSWidth    => s_dLSWidth, -- TODO: respect LS width
            o_RD         => s_dRD,
            o_RS1        => s_dRS1,
            o_RS2        => s_dRS2, 
            o_Imm        => s_dImm,
            o_BranchMode => s_dBranchMode,
            o_Break      => s_dBreak,
            o_IsBranch   => open,
            o_nInc2_Inc4 => s_dnInc2_Inc4,
            o_IPToALU    => s_dIPToALU
        );

    s_dAddr <= s_aluF;

    s_rfD <= s_mData     when (s_dRFSrc = work.my_enums.FROM_RAM)    else 
             s_aluF      when (s_dRFSrc = work.my_enums.FROM_ALU)    else 
             s_linkAddr  when (s_dRFSrc = work.my_enums.FROM_NEXTIP) else
             s_dImm      when (s_dRFSrc = work.my_enums.FROM_IMM)    else
             32x"0";

    g_CPURegisterFile: regfile
        port MAP(
            i_CLK => s_ngCLK,
            --i_CLK => s_gCLK, -- needs to be written on the negedge
            i_RST => i_RST,
            i_RS1 => s_dRS1,
            i_RS2 => s_dRS2,
            i_RD  => s_dRD,
            i_WE  => s_dRegWrite,
            i_D   => s_rfD,
            o_DS1 => s_DS1,
            o_DS2 => s_DS2
        );

    s_aluA <= s_ipAddr when (s_dIPToALU = '1') else
              s_DS1;

    s_aluB <= s_DS2 when (s_dALUSrc = '0') else
              s_dImm;

    g_CPUALU: alu
        port MAP(
            i_A     => s_aluA,
            i_B     => s_aluB,
            i_ALUOp => s_dALUOp,
            o_F     => s_aluF,
            o_Co    => s_oCo
        );

end mixed;
