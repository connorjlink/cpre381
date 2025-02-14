-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- RISCV_Processor.vhd
-- DESCRIPTION: This file contains a skeleton of a RISCV_Processor  
-- implementation.

-- 01.29.2019 by H3::Design created.
-- 02.11.2025 by Connor J. Link authored RISC-V implementation.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.RISCV_types.all;

entity RISCV_Processor is
    generic(
        N : integer := work.RISCV_types.DATA_WIDTH
    );
    port(
        iCLK      : in  std_logic;
        iRST      : in  std_logic;
        iInstLd   : in  std_logic;
        iInstAddr : in  std_logic_vector(N-1 downto 0);
        iInstExt  : in  std_logic_vector(N-1 downto 0);
        oALUOut   : out std_logic_vector(N-1 downto 0) -- TODO: Hook this up to the output of the ALU. It is important for synthesis that you have this output that can effectively be impacted by all other components so they are not optimized away.
    ); 
end RISCV_Processor;

architecture structure of RISCV_Processor is

-- Required data memory signals
signal s_DMemWr       : std_logic;                      -- TODO: use this signal as the final active high data memory write enable signal
signal s_DMemAddr     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory address input
signal s_DMemData     : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input
signal s_DMemOut      : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the data memory output
 
-- Required register file signals 
signal s_RegWr        : std_logic;                      -- TODO: use this signal as the final active high write enable input to the register file
signal s_RegWrAddr    : std_logic_vector(4 downto 0);   -- TODO: use this signal as the final destination register address input
signal s_RegWrData    : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the final data memory data input

-- Required instruction memory signals
signal s_IMemAddr     : std_logic_vector(N-1 downto 0); -- Do not assign this signal, assign to s_NextInstAddr instead
signal s_NextInstAddr : std_logic_vector(N-1 downto 0); -- TODO: use this signal as your intended final instruction memory address input.
signal s_Inst         : std_logic_vector(N-1 downto 0); -- TODO: use this signal as the instruction signal 

-- Required halt signal -- for simulation
signal s_Halt         : std_logic;  -- TODO: this signal indicates to the simulation that intended program execution has completed. (Opcode: 01 0100)

-- Required overflow signal -- for overflow exception detection
signal s_Ovfl         : std_logic;

component mem is
    generic(
        ADDR_WIDTH : integer;
        DATA_WIDTH : integer
    );
    port(
        clk  : in  std_logic;
        addr : in  std_logic_vector((ADDR_WIDTH-1) downto 0);
        data : in  std_logic_vector((DATA_WIDTH-1) downto 0);
        we   : in  std_logic := '1';
        q    : out std_logic_vector((DATA_WIDTH -1) downto 0)
    );
end component;


-- Signals to hold memory inputs and outputs
signal s_DMemDataExtended : std_logic_vector(31 downto 0);

-- Signals to hold the intermediate outputs from the register file
signal s_RS1Data : std_logic_vector(31 downto 0);
signal s_RS2Data : std_logic_vector(31 downto 0);

-- Signal to hold the ALU inputs and outputs
signal s_ALUOperand1 : std_logic_vector(31 downto 0);
signal s_ALUOperand2 : std_logic_vector(31 downto 0);
signal s_ALUResult   : std_logic_vector(31 downto 0);
signal s_ALUCarry    : std_logic;

-- Signals to hold the control lines from the driver
signal s_RFSrc      : natural; -- 0 = ALU, 1 = memory, 2 = IP+4
signal s_ALUSrc     : std_logic;
signal s_ALUOp      : natural;
signal s_BGUOp      : natural;
signal s_LSWidth    : natural;
signal s_RS1        : std_logic_vector(4 downto 0);
signal s_RS2        : std_logic_vector(4 downto 0);
signal s_Imm        : std_logic_vector(31 downto 0);
signal s_BranchMode : natural;
signal s_IPStride   : std_logic; -- 0 = inc2, 1 = inc4
signal s_SignExtend : std_logic; -- 0 = zero extend, 1 = sign extend
signal s_IPToALU    : std_logic;

-- Signals to handle the output of the BGU
signal s_Branch : std_logic;
-- Signals to hold the computed memory instruction address input to the IP
signal s_BranchAddr : std_logic_vector(31 downto 0);
-- Signal to output the contents of the instruction pointer
signal s_IPAddr : std_logic_vector(31 downto 0);

-- Signal to hold the modified clock
signal s_gCLK  : std_logic;
signal s_ngCLK : std_logic;

begin

    -- TODO: This is required to be your final input to your instruction memory. This provides a feasible method to externally load the memory module which means that the synthesis tool must assume it knows nothing about the values stored in the instruction memory. If this is not included, much, if not all of the design is optimized out because the synthesis tool will believe the memory to be all zeros.
    with iInstLd select
        s_IMemAddr <= s_NextInstAddr when '0',
                      iInstAddr      when others;

    IMem: mem
        generic map(
            ADDR_WIDTH => work.RISCV_types.ADDR_WIDTH,
            DATA_WIDTH => N
        )
        port map(
            clk  => iCLK, -- gCLK
            addr => s_IPAddr(11 downto 2),
            data => iInstExt,
            we   => iInstLd,
            q    => s_Inst
        );
  
    DMem: mem
        generic map(
            ADDR_WIDTH => work.RISCV_types.ADDR_WIDTH,
            DATA_WIDTH => N
        )
        port map(
            clk  => iCLK, --ngCLK
            addr => s_DMemAddr(11 downto 2),
            data => s_DMemData, -- ScaledDS2
            we   => s_DMemWr,
            q    => s_DMemOut
        );

    s_Ovfl <= '0'; -- RISC-V does not support overflow-checked arithmetic.
    
    s_BranchAddr <= std_logic_vector(signed(s_IPAddr)  + signed(s_Imm)) when (s_BranchMode = work.RISCV_types.JAL_OR_BCC) else
                    std_logic_vector(signed(s_RS1Data) + signed(s_Imm)) when (s_BranchMode = work.RISCV_types.JALR)       else 
                    (others => '0');

    g_InstructionPointerUnit: entity work.ip
        generic MAP(
            ResetAddress => 32x"00400000"
        )
        port MAP(
            i_CLK        => iCLK, -- FIXME: s_gCLK or iCLK?
            i_RST        => iRST,
            i_Load       => s_Branch,
            i_Addr       => s_BranchAddr,
            i_nInc2_Inc4 => s_IPStride,
            i_Stall      => '0',
            o_Addr       => s_IPAddr,
            o_LinkAddr   => s_NextInstAddr -- replaced from s_LinkAddr, for it represents the address to which to link should a jal/jalr take place
        );

    s_gCLK <= (not s_Halt) and iCLK;
    s_ngCLK <= not s_gCLK;

    g_CPUBranchUnit: entity work.bgu
        port MAP(
            i_CLK    => iCLK, --s_gCLK,
            i_DS1    => s_RS1Data,
            i_DS2    => s_RS2Data,
            i_BGUOp  => s_BGUOp,
            o_Branch => s_Branch
        );

    g_CPUDriver: entity work.driver
        port MAP(
            i_CLK        => iCLK, --s_gCLK,
            i_RST        => iRST,
            i_Insn       => s_Inst,
            i_MaskStall  => '0', -- TODO: this should not affect this single cycle model
            o_MemWrite   => s_DMemWr,
            o_RegWrite   => s_RegWr,
            o_RFSrc      => s_RFSrc,
            o_ALUSrc     => s_ALUSrc,
            o_ALUOp      => s_ALUOp,
            o_BGUOp      => s_BGUOp,
            o_LSWidth    => s_LSWidth,
            o_RD         => s_RegWrAddr,
            o_RS1        => s_RS1,
            o_RS2        => s_RS2, 
            o_Imm        => s_Imm,
            o_BranchMode => s_BranchMode,
            o_Break      => s_Halt, --open,
            o_IsBranch   => open,
            o_nInc2_Inc4 => s_IPStride,
            o_nZero_Sign => s_SignExtend,
            o_IPToALU    => s_IPToALU
        );

    g_CPURegisterFile: entity work.regfile
        port MAP(
            i_CLK => iCLK, -- FIXME: shouldn't this be written on the negative edge to avoid a data race? (s_ngCLK)
            i_RST => iRST,
            i_RS1 => s_RS1,
            i_RS2 => s_RS2,
            i_RD  => s_RegWrAddr,
            i_WE  => s_RegWr,
            i_D   => s_RegWrData,
            o_DS1 => s_RS1Data,
            o_DS2 => s_RS2Data
        );

    s_ALUOperand1 <= s_IPAddr when (s_IPToALU = '1') else
                     s_RS1Data;

    s_ALUOperand2 <= s_RS2Data when (s_ALUSrc = '0') else
                     s_Imm;

    g_CPUALU: entity work.alu
        port MAP(
            i_A     => s_ALUOperand1,
            i_B     => s_ALUOperand2,
            i_ALUOp => s_ALUOp,
            o_F     => s_ALUResult,
            o_Co    => s_ALUCarry
        );

    oALUOut <= s_ALUResult;
    s_DMemAddr <= s_ALUResult;

    -- NOTE: store instructions do not actually extend any contents in RISC-V.
    -- Since we are using word-addressable RAM, though, we need to zero-extend to the correct width to preserve unsigned value for storage.
    s_DMemData <= std_logic_vector(resize(unsigned(s_RS2Data(7  downto 0)), s_DMemData'length)) when (s_LSWidth = work.RISCV_types.BYTE) else
                  std_logic_vector(resize(unsigned(s_RS2Data(15 downto 0)), s_DMemData'length)) when (s_LSWidth = work.RISCV_types.HALF) else
                  std_logic_vector(resize(unsigned(s_RS2Data(31 downto 0)), s_DMemData'length)) when (s_LSWidth = work.RISCV_types.WORD) else
                  (others => '0');

    s_DMemDataExtended <= std_logic_vector(resize(unsigned(s_DMemOut(7  downto 0)), s_DMemDataExtended'length)) when (s_LSWidth = work.RISCV_types.BYTE and s_SignExtend = '0') else
                          std_logic_vector(resize(  signed(s_DMemOut(7  downto 0)), s_DMemDataExtended'length)) when (s_LSWidth = work.RISCV_types.BYTE and s_SignExtend = '1') else
                          std_logic_vector(resize(unsigned(s_DMemOut(15 downto 0)), s_DMemDataExtended'length)) when (s_LSWidth = work.RISCV_types.HALF and s_SignExtend = '0') else
                          std_logic_vector(resize(  signed(s_DMemOut(15 downto 0)), s_DMemDataExtended'length)) when (s_LSWidth = work.RISCV_types.HALF and s_SignExtend = '1') else
                          std_logic_vector(resize(unsigned(s_DMemOut(31 downto 0)), s_DMemDataExtended'length)) when (s_LSWidth = work.RISCV_types.WORD and s_SignExtend = '0') else
                          std_logic_vector(resize(  signed(s_DMemOut(31 downto 0)), s_DMemDataExtended'length)) when (s_LSWidth = work.RISCV_types.WORD and s_SignExtend = '1') else
                          (others => '0');

    s_RegWrData <= s_DMemDataExtended when (s_RFSrc = work.RISCV_types.FROM_RAM)    else 
                   s_ALUResult        when (s_RFSrc = work.RISCV_types.FROM_ALU)    else 
                   s_NextInstAddr     when (s_RFSrc = work.RISCV_types.FROM_NEXTIP) else
                   s_Imm              when (s_RFSrc = work.RISCV_types.FROM_IMM)    else
                   (others => '0');

end structure;

