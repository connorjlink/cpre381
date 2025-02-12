-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- software_cpu.vhd
-- DESCRIPTION: This file contains an implementation of a basic software-scheduled RISC-V processor core
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_types.all;
use work.my_records.all;

-- TODO LIST:
-- pipeline stalling

-- more broadly take in all signals for each block and pass forward
-- i.e., take iMem assign all values to oMem

-- modern EG
-- wire up insn_bufIPAddr to driver_rawIPAddr

entity software_cpu is
    port(i_CLK : in std_logic;
         i_RST : in std_logic);
end software_cpu;

architecture mixed of software_cpu is

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

component mem is
	generic(
		DATA_WIDTH : natural := 32;
		ADDR_WIDTH : natural := 10
	);
	port(
		clk		: in std_logic;
		addr	: in std_logic_vector((ADDR_WIDTH-1) downto 0);
		data	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		we		: in std_logic := '1';
		q		: out std_logic_vector((DATA_WIDTH -1) downto 0)
	);
end component;

component driver is
    port(
        i_CLK        : in  std_logic;
        i_RST        : in  std_logic;
        i_Insn       : in  std_logic_vector(31 downto 0);
        i_MaskStall  : in  std_logic;
        o_MemWrite   : out std_logic;
        o_RegWrite   : out std_logic;
        o_RFSrc      : out natural; 
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
        o_ipToALU    : out std_logic
    );
end component;

component reg_pipeline is
    generic(
        STAGE        : natural
    );
    port(
        i_CLK        : in  std_logic;
        i_RST        : in  std_logic;
        i_STALL      : in  std_logic;

        i_Signals    : in  work.my_records.controls_t;
        o_Signals    : out work.my_records.controls_t
    );
end component;

component reg_insn is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_STALL    : in  std_logic;

        i_IPAddr   : in  std_logic_vector(31 downto 0);
        o_IPAddr   : out std_logic_vector(31 downto 0);

        i_LinkAddr : in  std_logic_vector(31 downto 0);
        o_LinkAddr : out std_logic_vector(31 downto 0);

        i_Insn     : in  std_logic_vector(31 downto 0);
        o_Insn     : out std_logic_vector(31 downto 0)
    );
end component;

component reg_driver is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_STALL    : in  std_logic;

        i_MemWrite   : in  std_logic;
        o_MemWrite   : out std_logic;

        i_RegWrite   : in  std_logic;
        o_RegWrite   : out std_logic;

        i_RFSrc      : in  natural;
        o_RFSrc      : out natural;

        i_ALUSrc     : in  std_logic;
        o_ALUSrc     : out std_logic;

        i_ALUOp      : in  natural;
        o_ALUOp      : out natural;

        i_BGUOp      : in  natural;
        o_BGUOp      : out natural;

        i_LSWidth    : in  natural;
        o_LSWidth    : out natural;

        i_RD         : in  std_logic_vector(4 downto 0);
        o_RD         : out std_logic_vector(4 downto 0);

        i_RS1        : in  std_logic_vector(4 downto 0);
        o_RS1        : out std_logic_vector(4 downto 0);

        i_RS2        : in  std_logic_vector(4 downto 0);
        o_RS2        : out std_logic_vector(4 downto 0);

        i_DS1        : in  std_logic_vector(31 downto 0);
        o_DS1        : out std_logic_vector(31 downto 0);

        i_DS2        : in  std_logic_vector(31 downto 0);
        o_DS2        : out std_logic_vector(31 downto 0);

        i_Imm        : in  std_logic_vector(31 downto 0);
        o_Imm        : out std_logic_vector(31 downto 0);

        i_BranchMode : in  natural;
        o_BranchMode : out natural;

        i_nInc2_Inc4 : in  std_logic;
        o_nInc2_Inc4 : out std_logic;
        
        i_IPToALU    : in  std_logic;
        o_IPToALU    : out std_logic
    );
end component;

component reg_alu is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_STALL    : in  std_logic;

        i_F  : in  std_logic_vector(31 downto 0);
        o_F  : out std_logic_vector(31 downto 0);

        i_Co : in  std_logic;
        o_Co : out std_logic
    );
end component;

component reg_mem is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_STALL    : in  std_logic;

        i_Data     : in  std_logic_vector(31 downto 0);
        o_Data     : out std_logic_vector(31 downto 0)
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


-- Signal to hold the ALU inputs and outputs
signal s_aluA : std_logic_vector(31 downto 0);
signal s_aluB : std_logic_vector(31 downto 0);

-- Signal to hold the register file inputs and outputs
signal s_rfD : std_logic_vector(31 downto 0);

-- Signals to hold the outputs from the register file for writing back to the data memory block
signal s_CurrentDS1 : std_logic_vector(31 downto 0);
signal s_CurrentDS2 : std_logic_vector(31 downto 0);

-- Signals to support the instruction pointer logic
signal s_EffectiveAddr : std_logic_vector(31 downto 0);
signal s_Branch        : std_logic;
signal s_Stall         : std_logic;

-- Signals to support gated clock for breaking off execution
signal s_Break    : std_logic;
signal g_CLK      : std_logic;
signal g_nCLK     : std_logic;


-- Signals for instruction pipeline register
signal insn_rawIPAddr   : std_logic_vector(31 downto 0);
signal insn_bufIPAddr   : std_logic_vector(31 downto 0);

signal insn_rawLinkAddr : std_logic_vector(31 downto 0);
signal insn_bufLinkAddr : std_logic_vector(31 downto 0);

signal insn_rawInsn     : std_logic_vector(31 downto 0);
signal insn_bufInsn     : std_logic_vector(31 downto 0);


-- Signals for driver pipeline register
signal driver_rawIPAddr     : std_logic_vector(31 downto 0);
signal driver_bufIPAddr     : std_logic_vector(31 downto 0);
 
signal driver_rawLinkAddr   : std_logic_vector(31 downto 0);
signal driver_bufLinkAddr   : std_logic_vector(31 downto 0);
 
signal driver_rawInsn       : std_logic_vector(31 downto 0);
signal driver_bufInsn       : std_logic_vector(31 downto 0);

signal driver_rawMemWrite   : std_logic;
signal driver_bufMemWrite   : std_logic;

signal driver_rawRegWrite   : std_logic;
signal driver_bufRegWrite   : std_logic;

signal driver_rawRFSrc      : natural;
signal driver_bufRFSrc      : natural;

signal driver_rawALUSrc     : std_logic;
signal driver_bufALUSrc     : std_logic;

signal driver_rawALUOp      : natural;
signal driver_bufALUOp      : natural;

signal driver_rawBGUOp      : natural;
signal driver_bufBGUOp      : natural;

signal driver_rawLSWidth    : natural;
signal driver_bufLSWidth    : natural;

signal driver_rawRD         : std_logic_vector(4 downto 0);
signal driver_bufRD         : std_logic_vector(4 downto 0);

signal driver_rawRS1        : std_logic_vector(4 downto 0);
signal driver_bufRS1        : std_logic_vector(4 downto 0);

signal driver_rawRS2        : std_logic_vector(4 downto 0);
signal driver_bufRS2        : std_logic_vector(4 downto 0);

-- NOTE: no raw signals because the register read occurs live outside of the driver itself
signal driver_bufDS1        : std_logic_vector(31 downto 0);
signal driver_bufDS2        : std_logic_vector(31 downto 0);

signal driver_rawImm        : std_logic_vector(31 downto 0);
signal driver_bufImm        : std_logic_vector(31 downto 0);

signal driver_rawBranchMode : natural;
signal driver_bufBranchMode : natural;

signal driver_rawnInc2_Inc4 : std_logic;
signal driver_bufnInc2_Inc4 : std_logic;

signal driver_rawIPToALU    : std_logic;
signal driver_bufIPToALU    : std_logic;


-- Signals for ALU pipeline register
signal alu_rawIPAddr     : std_logic_vector(31 downto 0);
signal alu_bufIPAddr     : std_logic_vector(31 downto 0);
 
signal alu_rawLinkAddr   : std_logic_vector(31 downto 0);
signal alu_bufLinkAddr   : std_logic_vector(31 downto 0);
 
signal alu_rawInsn       : std_logic_vector(31 downto 0);
signal alu_bufInsn       : std_logic_vector(31 downto 0);

signal alu_rawMemWrite   : std_logic;
signal alu_bufMemWrite   : std_logic;

signal alu_rawRegWrite   : std_logic;
signal alu_bufRegWrite   : std_logic;

signal alu_rawRFSrc      : natural;
signal alu_bufRFSrc      : natural;

signal alu_rawALUSrc     : std_logic;
signal alu_bufALUSrc     : std_logic;

signal alu_rawALUOp      : natural;
signal alu_bufALUOp      : natural;

signal alu_rawBGUOp      : natural;
signal alu_bufBGUOp      : natural;

signal alu_rawLSWidth    : natural;
signal alu_bufLSWidth    : natural;

signal alu_rawRD         : std_logic_vector(4 downto 0);
signal alu_bufRD         : std_logic_vector(4 downto 0);

signal alu_rawRS1        : std_logic_vector(4 downto 0);
signal alu_bufRS1        : std_logic_vector(4 downto 0);

signal alu_rawRS2        : std_logic_vector(4 downto 0);
signal alu_bufRS2        : std_logic_vector(4 downto 0);

signal alu_rawDS1        : std_logic_vector(31 downto 0);
signal alu_bufDS1        : std_logic_vector(31 downto 0);

signal alu_rawDS2        : std_logic_vector(31 downto 0);
signal alu_bufDS2        : std_logic_vector(31 downto 0);

signal alu_rawImm        : std_logic_vector(31 downto 0);
signal alu_bufImm        : std_logic_vector(31 downto 0);

signal alu_rawBranchMode : natural;
signal alu_bufBranchMode : natural;

signal alu_rawnInc2_Inc4 : std_logic;
signal alu_bufnInc2_Inc4 : std_logic;

signal alu_rawIPToALU    : std_logic;
signal alu_bufIPToALU    : std_logic;

signal alu_rawF          : std_logic_vector(31 downto 0);
signal alu_bufF          : std_logic_vector(31 downto 0);

signal alu_rawCo         : std_logic;
signal alu_bufCo         : std_logic;


-- Signals for memory pipeline register
signal mem_rawIPAddr     : std_logic_vector(31 downto 0);
signal mem_bufIPAddr     : std_logic_vector(31 downto 0);
 
signal mem_rawLinkAddr   : std_logic_vector(31 downto 0);
signal mem_bufLinkAddr   : std_logic_vector(31 downto 0);
 
signal mem_rawInsn       : std_logic_vector(31 downto 0);
signal mem_bufInsn       : std_logic_vector(31 downto 0);

signal mem_rawMemWrite   : std_logic;
signal mem_bufMemWrite   : std_logic;

signal mem_rawRegWrite   : std_logic;
signal mem_bufRegWrite   : std_logic;

signal mem_rawRFSrc      : natural;
signal mem_bufRFSrc      : natural;

signal mem_rawALUSrc     : std_logic;
signal mem_bufALUSrc     : std_logic;

signal mem_rawALUOp      : natural;
signal mem_bufALUOp      : natural;

signal mem_rawBGUOp      : natural;
signal mem_bufBGUOp      : natural;

signal mem_rawLSWidth    : natural;
signal mem_bufLSWidth    : natural;

signal mem_rawRD         : std_logic_vector(4 downto 0);
signal mem_bufRD         : std_logic_vector(4 downto 0);

signal mem_rawRS1        : std_logic_vector(4 downto 0);
signal mem_bufRS1        : std_logic_vector(4 downto 0);

signal mem_rawRS2        : std_logic_vector(4 downto 0);
signal mem_bufRS2        : std_logic_vector(4 downto 0);

signal mem_rawDS1        : std_logic_vector(31 downto 0);
signal mem_bufDS1        : std_logic_vector(31 downto 0);

signal mem_rawDS2        : std_logic_vector(31 downto 0);
signal mem_bufDS2        : std_logic_vector(31 downto 0);

signal mem_rawImm        : std_logic_vector(31 downto 0);
signal mem_bufImm        : std_logic_vector(31 downto 0);

signal mem_rawBranchMode : natural;
signal mem_bufBranchMode : natural;

signal mem_rawnInc2_Inc4 : std_logic;
signal mem_bufnInc2_Inc4 : std_logic;

signal mem_rawIPToALU    : std_logic;
signal mem_bufIPToALU    : std_logic;

signal mem_rawF          : std_logic_vector(31 downto 0);
signal mem_bufF          : std_logic_vector(31 downto 0);

signal mem_rawCo         : std_logic;
signal mem_bufCo         : std_logic;

signal mem_rawData       : std_logic_vector(31 downto 0);
signal mem_bufData       : std_logic_vector(31 downto 0);


begin

    g_CLK <= i_CLK and not s_Break;
    g_nCLK <= not g_CLK;

    s_EffectiveAddr <= std_logic_vector(signed(mem_bufIPAddr) + signed(mem_bufImm)) when (mem_bufBranchMode = work.RISCV_types.JAL)  else
                       std_logic_vector(signed(mem_bufDS1)    + signed(mem_bufImm)) when (mem_bufBranchMode = work.RISCV_types.JALR) else 
                       std_logic_vector(signed(mem_bufIPAddr) + signed(mem_bufImm)) when (mem_bufBranchMode = work.RISCV_types.BCC)  else
                       32x"0";

    SoftwareCPU_InstructionPointer: ip
        generic MAP(
            ResetAddress => 32x"0" -- overriding this for testing purposes
        )
        port MAP(
            i_CLK   => g_nCLK,
            i_RST   => i_RST,
            i_Stall => s_Stall, -- FIXME:

            i_Addr       => s_EffectiveAddr, -- FIXME:
            i_Load       => s_Branch, -- TODO: figure out branching here more accurately
            i_nInc2_Inc4 => driver_rawnInc2_Inc4, -- FIXME: is this too late in the pipeline to decide how far to stride each instruction?

            o_Addr       => insn_rawIPAddr,
            o_LinkAddr   => insn_rawLinkAddr
        );

    SoftwareCPU_InstructionMemory: mem
        generic MAP(
            DATA_WIDTH => 32,
            ADDR_WIDTH => 10
        )
        port MAP(
            clk  => g_CLK,
            addr => insn_rawIPAddr(11 downto 2), -- divide instruction address by four since each address is one word
            data => (others => '0'), -- ROM
            we   => '0',
            q    => insn_rawInsn
        );

    -- Instruction to Driver stage Register(s)
    -----------------------------------------------
    driver_rawIPAddr   <= insn_bufIPAddr;
    driver_rawLinkAddr <= insn_bufLinkAddr;
    driver_rawInsn     <= insn_bufInsn;

    SoftwareCPU_Insn_IR: reg_insn
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => s_Stall, -- FIXME:
            
            i_IPAddr   => insn_rawIPAddr,
            o_IPAddr   => insn_bufIPAddr,

            i_LinkAddr => insn_rawLinkAddr,
            o_LinkAddr => insn_bufLinkAddr,

            i_Insn     => insn_rawInsn,
            o_Insn     => insn_bufInsn
        );
    -----------------------------------------------


    SoftwareCPU_Driver: driver
        port MAP(
            i_CLK => g_CLK,
            i_RST => i_RST,

            i_Insn       => insn_rawInsn, -- FIXME: could this give quicker results?
            i_MaskStall  => s_Branch,

            o_MemWrite   => driver_rawMemWrite,
            o_RegWrite   => driver_rawRegWrite,
            o_RFSrc      => driver_rawRFSrc,
            o_ALUSrc     => driver_rawALUSrc,
            o_ALUOp      => driver_rawALUOp,
            o_BGUOp      => driver_rawBGUOp,
            o_LSWidth    => driver_rawLSWidth,
            o_RD         => driver_rawRD,
            o_RS1        => driver_rawRS1,
            o_RS2        => driver_rawRS2,
            o_Imm        => driver_rawImm,
            o_BranchMode => driver_rawBranchMode,
            o_Break      => s_Break,
            o_IsBranch   => s_Stall,
            o_nInc2_Inc4 => driver_rawnInc2_Inc4,
            o_ipToALU    => driver_rawIPToALU
        );


    -- Driver to ALU stage Register(s)
    -----------------------------------------------
    alu_rawIPAddr     <= driver_bufIPAddr;
    alu_rawLinkAddr   <= driver_bufLinkAddr;
    alu_rawInsn       <= driver_bufInsn;

    alu_rawMemWrite   <= driver_bufMemWrite;
    alu_rawRegWrite   <= driver_bufRegWrite;
    alu_rawRFSrc      <= driver_bufRFSrc;
    alu_rawALUSrc     <= driver_bufALUSrc;
    alu_rawALUOp      <= driver_bufALUOp;
    alu_rawBGUOp      <= driver_bufBGUOp;
    alu_rawLSWidth    <= driver_bufLSWidth;
    alu_rawRD         <= driver_bufRD;
    alu_rawRS1        <= driver_bufRS1;
    alu_rawRS2        <= driver_bufRS2;
    alu_rawImm        <= driver_bufImm;
    alu_rawBranchMode <= driver_bufBranchMode;
    alu_rawnInc2_Inc4 <= driver_bufnInc2_Inc4;
    alu_rawIPToALU    <= driver_bufIPToALU;

    alu_rawDS1        <= driver_bufDS1;
    alu_rawDS2        <= driver_bufDS2;

    SoftwareCPU_Driver_IR: reg_insn
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0', -- TODO:

            i_IPAddr   => driver_rawIPAddr,
            o_IPAddr   => driver_bufIPAddr,

            i_LinkAddr => driver_rawLinkAddr,
            o_LinkAddr => driver_bufLinkAddr,

            i_Insn     => driver_rawInsn,
            o_Insn     => driver_bufInsn
        );

    SoftwareCPU_Driver_DR: reg_driver
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0', -- TODO:

            i_MemWrite   => driver_rawMemWrite,
            o_MemWrite   => driver_bufMemWrite,

            i_RegWrite   => driver_rawRegWrite,
            o_RegWrite   => driver_bufRegWrite,

            i_RFSrc      => driver_rawRFSrc,
            o_RFSrc      => driver_bufRFSrc,

            i_ALUSrc     => driver_rawALUSrc,
            o_ALUSrc     => driver_bufALUSrc,

            i_ALUOp      => driver_rawALUOp,
            o_ALUOp      => driver_bufALUOp,

            i_BGUOp      => driver_rawBGUOp,
            o_BGUOp      => driver_bufBGUOp,

            i_LSWidth    => driver_rawLSWidth,
            o_LSWidth    => driver_bufLSWidth,

            i_RD         => driver_rawRD,
            o_RD         => driver_bufRD,

            i_RS1        => driver_rawRS1,
            o_RS1        => driver_bufRS1,

            i_RS2        => driver_rawRS2,
            o_RS2        => driver_bufRS2,

            i_DS1        => s_CurrentDS1,
            o_DS1        => driver_bufDS1,

            i_DS2        => s_CurrentDS2,
            o_DS2        => driver_bufDS2,

            i_Imm        => driver_rawImm,
            o_Imm        => driver_bufImm,

            i_BranchMode => driver_rawBranchMode,
            o_BranchMode => driver_bufBranchMode,

            i_nInc2_Inc4 => driver_rawnInc2_Inc4,
            o_nInc2_Inc4 => driver_bufnInc2_Inc4,
            
            i_IPToALU    => driver_rawIPToALU,
            o_IPToALU    => driver_bufIPToALU
        );
    -----------------------------------------------


    s_aluA <= driver_bufIPAddr when (driver_bufIPToALU = '1') else
              driver_bufDS1    when (driver_bufIPToALU = '0') else
              (others => '0');

    s_aluB <= driver_bufImm    when (driver_bufALUSrc = '1') else
              driver_bufDS2    when (driver_bufALUSrc = '0') else
              (others => '0');

    SoftwareCPU_ALU: alu
        port MAP(
            i_A     => s_aluA,
            i_B     => s_aluB,
            i_ALUOp => alu_rawALUOp,
            o_F     => alu_rawF,
            o_Co    => alu_rawCo
        );


    -- ALU to Mem stage Register(s)
    -----------------------------------------------
    mem_rawIPAddr     <= alu_bufIPAddr;
    mem_rawLinkAddr   <= alu_bufLinkAddr;
    mem_rawInsn       <= alu_bufInsn;

    mem_rawMemWrite   <= alu_bufMemWrite;
    mem_rawRegWrite   <= alu_bufRegWrite;
    mem_rawRFSrc      <= alu_bufRFSrc;
    mem_rawALUSrc     <= alu_bufALUSrc;
    mem_rawALUOp      <= alu_bufALUOp;
    mem_rawBGUOp      <= alu_bufBGUOp;
    mem_rawLSWidth    <= alu_bufLSWidth;
    mem_rawRD         <= alu_bufRD;
    mem_rawRS1        <= alu_bufRS1;
    mem_rawRS2        <= alu_bufRS2;
    mem_rawImm        <= alu_bufImm;
    mem_rawBranchMode <= alu_bufBranchMode;
    mem_rawnInc2_Inc4 <= alu_bufnInc2_Inc4;
    mem_rawIPToALU    <= alu_bufIPToALU;

    mem_rawDS1        <= alu_bufDS1;
    mem_rawDS2        <= alu_bufDS2;

    mem_rawF          <= alu_bufF;
    mem_rawCo         <= alu_bufCo;

    SoftwareCPU_ALU_IR: reg_insn
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0', -- TODO:

            i_IPAddr   => alu_rawIPAddr,
            o_IPAddr   => alu_bufIPAddr,

            i_LinkAddr => alu_rawLinkAddr,
            o_LinkAddr => alu_bufLinkAddr,

            i_Insn     => alu_rawInsn,
            o_Insn     => alu_bufInsn
        );

    SoftwareCPU_ALU_DR: reg_driver
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0', -- TODO:

            i_MemWrite   => alu_rawMemWrite,
            o_MemWrite   => alu_bufMemWrite,

            i_RegWrite   => alu_rawRegWrite,
            o_RegWrite   => alu_bufRegWrite,

            i_RFSrc      => alu_rawRFSrc,
            o_RFSrc      => alu_bufRFSrc,

            i_ALUSrc     => alu_rawALUSrc,
            o_ALUSrc     => alu_bufALUSrc,

            i_ALUOp      => alu_rawALUOp,
            o_ALUOp      => alu_bufALUOp,

            i_BGUOp      => alu_rawBGUOp,
            o_BGUOp      => alu_bufBGUOp,

            i_LSWidth    => alu_rawLSWidth,
            o_LSWidth    => alu_bufLSWidth,

            i_RD         => alu_rawRD,
            o_RD         => alu_bufRD,

            i_RS1        => alu_rawRS1,
            o_RS1        => alu_bufRS1,

            i_RS2        => alu_rawRS2,
            o_RS2        => alu_bufRS2,

            i_DS1        => alu_rawDS1,
            o_DS1        => alu_bufDS1,

            i_DS2        => alu_rawDS2,
            o_DS2        => alu_bufDS2,

            i_Imm        => alu_rawImm,
            o_Imm        => alu_bufImm,

            i_BranchMode => alu_rawBranchMode,
            o_BranchMode => alu_bufBranchMode,

            i_nInc2_Inc4 => alu_rawnInc2_Inc4,
            o_nInc2_Inc4 => alu_bufnInc2_Inc4,
            
            i_IPToALU    => alu_rawIPToALU,
            o_IPToALU    => alu_bufIPToALU
        );

    SoftwareCPU_ALU_AR: reg_alu
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0', -- TODO:

            i_F   => alu_rawF,
            o_F   => alu_bufF,

            i_Co  => alu_rawCo,
            o_Co  => alu_bufCo
        );
    -----------------------------------------------


    SoftwareCPU_DataMemory: mem
        generic MAP(
            DATA_WIDTH => 32,
            ADDR_WIDTH => 10
        )
        port MAP(
            clk  => g_nCLK,
            addr => mem_rawF(11 downto 2), -- divide instruction address by four since each address is one word
            data => mem_rawDS2,
            we   => mem_rawMemWrite,
            q    => mem_rawData
        );
    

    -- Mem to RF stage Register(s)
    -----------------------------------------------
    SoftwareCPU_MEM_IR: reg_insn
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0', -- TODO:

            i_IPAddr   => mem_rawIPAddr,
            o_IPAddr   => mem_bufIPAddr,

            i_LinkAddr => mem_rawLinkAddr,
            o_LinkAddr => mem_bufLinkAddr,

            i_Insn     => mem_rawInsn,
            o_Insn     => mem_bufInsn
        );

    SoftwareCPU_MEM_DR: reg_driver
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0', -- TODO:

            i_MemWrite   => mem_rawMemWrite,
            o_MemWrite   => mem_bufMemWrite,

            i_RegWrite   => mem_rawRegWrite,
            o_RegWrite   => mem_bufRegWrite,

            i_RFSrc      => mem_rawRFSrc,
            o_RFSrc      => mem_bufRFSrc,

            i_ALUSrc     => mem_rawALUSrc,
            o_ALUSrc     => mem_bufALUSrc,

            i_ALUOp      => mem_rawALUOp,
            o_ALUOp      => mem_bufALUOp,

            i_BGUOp      => mem_rawBGUOp,
            o_BGUOp      => mem_bufBGUOp,

            i_LSWidth    => mem_rawLSWidth,
            o_LSWidth    => mem_bufLSWidth,

            i_RD         => mem_rawRD,
            o_RD         => mem_bufRD,

            i_RS1        => mem_rawRS1,
            o_RS1        => mem_bufRS1,

            i_RS2        => mem_rawRS2,
            o_RS2        => mem_bufRS2,

            i_DS1        => mem_rawDS1,
            o_DS1        => mem_bufDS1,

            i_DS2        => mem_rawDS2,
            o_DS2        => mem_bufDS2,

            i_Imm        => mem_rawImm,
            o_Imm        => mem_bufImm,

            i_BranchMode => mem_rawBranchMode,
            o_BranchMode => mem_bufBranchMode,

            i_nInc2_Inc4 => mem_rawnInc2_Inc4,
            o_nInc2_Inc4 => mem_bufnInc2_Inc4,
            
            i_IPToALU    => mem_rawIPToALU,
            o_IPToALU    => mem_bufIPToALU
        );

    SoftwareCPU_MEM_AR: reg_alu
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0', -- TODO:

            i_F   => mem_rawF,
            o_F   => mem_bufF,

            i_Co  => mem_rawCo,
            o_Co  => mem_bufCo
        );

    SoftwareCPU_MEM_MR: reg_mem
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0', -- TODO:

            i_Data => mem_rawData,
            o_Data => mem_bufData
        );
    -----------------------------------------------

    g_CPUBranchUnit: bgu
        port MAP(
            i_CLK => g_CLK,
            i_DS1 => mem_bufDS1,
            i_DS2 => mem_bufDS2,
            i_BGUOp => mem_bufBGUOp,
            o_Branch => s_Branch
        );

    s_rfD <= mem_bufData     when (mem_bufRFSrc = work.RISCV_types.FROM_RAM)    else 
             mem_bufF        when (mem_bufRFSrc = work.RISCV_types.FROM_ALU)    else 
             mem_bufLinkAddr when (mem_bufRFSrc = work.RISCV_types.FROM_NEXTIP) else
             mem_bufImm      when (mem_bufRFSrc = work.RISCV_types.FROM_IMM)    else
             (others => '0');

    SoftwareCPU_RegisterFile: regfile
        port MAP(
            i_CLK => g_nCLK, -- not obvious is this should be posedge or negedge
            i_RST => i_RST,

            -- ISSUE: I am having a data race condition between the written RS2 data value from the previous instruction and the current one trying to read it
            -- I write 1 ato x10 at exactly the same positive edge in my ALU tries to read x10 to get its operands.

            -- it appears this is a read after write hazard and the only solution is to stall :(
            -- or, insert a NOP

            i_RS1 => driver_rawRS1, --mem_bufRS1,
            i_RS2 => driver_rawRS2, --mem_bufRS2,
            i_RD  => mem_bufRD,
            i_WE  => mem_bufRegWrite,
            i_D   => s_rfD,
            o_DS1 => s_CurrentDS1,
            o_DS2 => s_CurrentDS2
        );

end mixed;