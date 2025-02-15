-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- SW_RISCV_Processor.vhd
-- DESCRIPTION: This file contains a skeleton of a software-scheduled 
-- pipelined RISCV_Processor implementation.

-- 01.29.2019 by H3::Design created.
-- 02.11.2025 by Connor J. Link authored RISC-V implementation.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.RISCV_types.all;

-- TODO LIST:
-- pipeline stalling

-- more broadly take in all signals for each block and pass forward
-- i.e., take iMem assign all values to oMem

-- modern EG
-- wire up insn_bufIPAddr to driver_rawIPAddr


entity SW_RISCV_Processor is
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
end SW_RISCV_Processor;

architecture structure of SW_RISCV_Processor is

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

-- FIXME: Required overflow signal -- for overflow exception detection
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
signal s_DMemOutExtended : std_logic_vector(31 downto 0);

-- Signals to hold the intermediate outputs from the register file
signal s_RS1Data : std_logic_vector(31 downto 0);
signal s_RS2Data : std_logic_vector(31 downto 0);

-- Signal to hold the ALU inputs and outputs
signal s_ALUOperand1 : std_logic_vector(31 downto 0);
signal s_RealALUOperand1 : std_logic_vector(31 downto 0);
signal s_ALUOperand2 : std_logic_vector(31 downto 0);
signal s_RealALUOperand2 : std_logic_vector(31 downto 0);

-- Signals to handle the output of the BGU
signal s_Branch : std_logic;

-- Signal to hold the modified clock
signal s_gCLK  : std_logic;
signal s_ngCLK : std_logic;

-- Signals to hold the computed memory instruction address input to the IP
signal s_BranchAddr : std_logic_vector(31 downto 0);

-- Signal to output the contents of the instruction pointer
signal s_IPAddr : std_logic_vector(31 downto 0);
signal s_IPBreak : std_logic;
signal s_IsLoad : std_logic;

----------------------------------------------------------------------------------
---- Pipeline Data Signals
---- NOTE: the two identifiers are not the source and destination connections
---- The first is the source of the pipeline register, and the second is the stage
---- operating the pool of signals at hand.
----
---- Thus, alu_insn_raw are the `input` signals to the pipeline register after the ALU
---- stage driven by the instruction register (so IPAddr, Insn, etc.)
----------------------------------------------------------------------------------
signal insn_insn_raw,     insn_insn_buf     : work.RISCV_types.insn_record_t;

signal driver_insn_raw,   driver_insn_buf   : work.RISCV_types.insn_record_t;
signal driver_driver_raw, driver_driver_buf : work.RISCV_types.driver_record_t;

signal alu_insn_raw,      alu_insn_buf      : work.RISCV_types.insn_record_t;
signal alu_driver_raw,    alu_driver_buf    : work.RISCV_types.driver_record_t;
signal alu_alu_raw,       alu_alu_buf       : work.RISCV_types.alu_record_t;

signal mem_insn_raw,      mem_insn_buf      : work.RISCV_types.insn_record_t;
signal mem_driver_raw,    mem_driver_buf    : work.RISCV_types.driver_record_t;
signal mem_alu_raw,       mem_alu_buf       : work.RISCV_types.alu_record_t;
signal mem_mem_raw,       mem_mem_buf       : work.RISCV_types.mem_record_t;


signal insn_Stall,   insn_Flush   : std_logic := '0';
signal driver_Stall, driver_Flush : std_logic := '0';
signal alu_Stall,    alu_Flush    : std_logic := '0';
signal mem_Stall,    mem_Flush    : std_logic := '0';
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
---- Pipeline Data Signals
----------------------------------------------------------------------------------
signal s_ForwardALUToALUOperand1, s_ForwardALUToALUOperand2, s_ForwardMemToALUOperand1, s_ForwardMemToALUOperand2 : std_logic := '0';
signal s_ForwardMemToDriverRS1,   s_ForwardMemToDriverRS2,   s_ForwardALUToDriverRS1,   s_ForwardALUToDriverRS2   : std_logic := '0';
----------------------------------------------------------------------------------


begin

    s_Ovfl <= '0'; -- RISC-V does not support overflow-checked arithmetic.
    
    s_gCLK  <= (not s_Halt) and iCLK;
    s_ngCLK <= not s_gCLK;

    -- TODO: This is required to be your final input to your instruction memory. This provides a feasible method to externally load the memory module which means that the synthesis tool must assume it knows nothing about the values stored in the instruction memory. If this is not included, much, if not all of the design is optimized out because the synthesis tool will believe the memory to be all zeros.
    with iInstLd select
        s_IMemAddr <= s_NextInstAddr when '0',
                      iInstAddr      when others;

    -- FIXME: connect to new control signals
    IMem: mem
        generic map(
            ADDR_WIDTH => work.RISCV_types.ADDR_WIDTH,
            DATA_WIDTH => N
        )
        port map(
            clk  => s_gCLK, -- gCLK
            addr => s_IPAddr(11 downto 2),
            data => iInstExt,
            we   => iInstLd,
            q    => s_Inst
        );
  
    -- FIXME: connect to new control signals
    DMem: mem
        generic map(
            ADDR_WIDTH => work.RISCV_types.ADDR_WIDTH,
            DATA_WIDTH => N
        )
        port map(
            clk  => s_ngCLK, --iCLK, --ngCLK
            addr => s_DMemAddr(11 downto 2),
            data => s_DMemData,
            we   => s_DMemWr,
            q    => s_DMemOut
        );

    s_DMemWr <= alu_driver_buf.MemWrite;
    mem_mem_raw.Data <= s_DMemOut;

    -- IMPLEMENTATION STARTS HERE

    -----------------------------------------------------
    ---- Instruction -> Driver stage register(s)
    -----------------------------------------------------

    SWCPU_Insn_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => insn_Stall,
            i_Flush => insn_Flush,
        
            i_Signals => insn_insn_raw,
            o_Signals => insn_insn_buf
        );

    driver_insn_raw <= insn_insn_buf;
        
    -----------------------------------------------------


    -----------------------------------------------------
    ---- Driver -> ALU stage register(s)
    -----------------------------------------------------

    SWCPU_Driver_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => driver_Stall,
            i_Flush => driver_Flush,
        
            i_Signals => driver_insn_raw,
            o_Signals => driver_insn_buf
        );

    SWCPU_Driver_DR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => driver_Stall,
            i_Flush => driver_Flush,
        
            i_Signals => driver_driver_raw,
            o_Signals => driver_driver_buf
        );

    alu_insn_raw   <= driver_insn_buf;
    alu_driver_raw <= driver_driver_buf;

    -----------------------------------------------------


    -----------------------------------------------------
    ---- ALU -> Memory stage register(s)
    -----------------------------------------------------

    SWCPU_ALU_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => alu_Stall,
            i_Flush => alu_Flush,
        
            i_Signals => alu_insn_raw,
            o_Signals => alu_insn_buf
        );

    SWCPU_ALU_DR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => alu_Stall,
            i_Flush => alu_Flush,
        
            i_Signals => alu_driver_raw,
            o_Signals => alu_driver_buf
        );

    SWCPU_ALU_AR: entity work.reg_alu
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => alu_Stall,
            i_Flush => alu_Flush,
        
            i_Signals => alu_alu_raw,
            o_Signals => alu_alu_buf
        );


    mem_insn_raw   <= alu_insn_buf;
    mem_driver_raw <= alu_driver_buf;
    mem_alu_raw    <= alu_alu_buf;

    -----------------------------------------------------


    -----------------------------------------------------
    ---- Memory -> Register File stage register(s)
    -----------------------------------------------------

    SWCPU_Mem_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => mem_Stall,
            i_Flush => mem_Flush,
        
            i_Signals => mem_insn_raw,
            o_Signals => mem_insn_buf
        );

    SWCPU_Mem_DR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => mem_Stall,
            i_Flush => mem_Flush,
        
            i_Signals => mem_driver_raw,
            o_Signals => mem_driver_buf
        );

    SWCPU_Mem_AR: entity work.reg_alu
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => mem_Stall,
            i_Flush => mem_Flush,
        
            i_Signals => mem_alu_raw,
            o_Signals => mem_alu_buf
        ); 
    

    SWCPU_Mem_MR: entity work.reg_mem
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => mem_Stall,
            i_Flush => mem_Flush,
        
            i_Signals => mem_mem_raw,
            o_Signals => mem_mem_buf
        );

    -----------------------------------------------------


    s_BranchAddr <= std_logic_vector(signed(mem_insn_buf.IPAddr) + signed(mem_driver_buf.Imm)) when (mem_driver_buf.BranchMode = work.RISCV_types.JAL_OR_BCC) else
                    std_logic_vector(signed(mem_driver_buf.DS1)  + signed(mem_driver_buf.Imm)) when (mem_driver_buf.BranchMode = work.RISCV_types.JALR)       else 
                    (others => '0');

    SWCPU_IP: entity work.ip
        generic MAP(
            ResetAddress => 32x"0"
        )
        port MAP(
            i_CLK        => (iCLK and not s_IPBreak), -- TODO: i_CLK or s_gCLK
            i_RST        => iRST,
            i_Stall      => insn_Stall, -- FIXME:
            i_Load       => s_Branch,
            i_Addr       => s_BranchAddr, -- FIXME:
            -- BELOW: might be 1 pipeline stage ahead (one cycle off)
            i_nInc2_Inc4 => driver_driver_raw.IPStride, -- FIXME: is this too late in the pipeline to decide how far to stride each instruction?
            o_Addr       => s_IPAddr,
            o_LinkAddr   => s_NextInstAddr 
        );
    insn_insn_raw.IPAddr   <= s_IPAddr;
    insn_insn_raw.LinkAddr <= s_NextInstAddr;
    insn_insn_raw.Insn     <= s_Inst;


    SWCPU_BGU: entity work.bgu
        port MAP(
            i_CLK    => s_gCLK,
            -- these signals might need to be hooked up to earlier in the pipeline
            -- the like the raw output from the driver or something in order to later forward ht evlaue that we n eed
            i_DS1    => mem_driver_buf.DS1, --s_RS1Data,
            i_DS2    => mem_driver_buf.DS2, --s_RS2Data,
            i_BGUOp  => mem_driver_buf.BGUOp, --s_dBGUOp,
            o_Branch => s_Branch
        );


    SWCPU_Driver: entity work.driver
        port MAP(
            i_CLK        => s_gCLK,
            i_RST        => iRST,
            i_Insn       => driver_insn_raw.Insn, -- s_Inst,
            o_MemWrite   => driver_driver_raw.MemWrite, -- s_DMemWr
            o_RegWrite   => driver_driver_raw.RegWrite, -- s_RegWr,
            o_RFSrc      => driver_driver_raw.RFSrc,
            o_ALUSrc     => driver_driver_raw.ALUSrc,
            o_ALUOp      => driver_driver_raw.ALUOp,
            o_BGUOp      => driver_driver_raw.BGUOp,
            o_LSWidth    => driver_driver_raw.LSWidth,
            o_RD         => driver_driver_raw.RD, -- s_RegWrAddr,
            o_RS1        => driver_driver_raw.RS1,
            o_RS2        => driver_driver_raw.RS2, 
            o_Imm        => driver_driver_raw.Imm,
            o_BranchMode => driver_driver_raw.BranchMode,
            o_Break      => s_Halt,
            o_IsBranch   => driver_driver_raw.IsBranch,
            o_IPStride   => driver_driver_raw.IPStride,
            o_SignExtend => driver_driver_raw.SignExtend,
            o_IPToALU    => driver_driver_raw.IPToALU
        );

    driver_driver_raw.DS1 <= s_RS1Data;
    driver_driver_raw.DS2 <= s_RS2Data;


    s_RegWrData <= s_DMemOutExtended     when (mem_driver_buf.RFSrc = work.RISCV_types.FROM_RAM)    else 
                   mem_alu_buf.F         when (mem_driver_buf.RFSrc = work.RISCV_types.FROM_ALU)    else 
                   mem_insn_buf.LinkAddr when (mem_driver_buf.RFSrc = work.RISCV_types.FROM_NEXTIP) else
                   mem_driver_buf.Imm    when (mem_driver_buf.RFSrc = work.RISCV_types.FROM_IMM)    else
                   (others => '0');

    s_RegWr <= mem_driver_buf.RegWrite;
    s_RegWrAddr <= mem_driver_buf.RD;

    SWCPU_RegisterFile: entity work.regfile
        port MAP(
            i_CLK => s_ngCLK,
            --i_CLK => s_gCLK, -- needs to be written on the negedge
            i_RST => iRST,
            -- following, I guess that register reads HAVE to happen in the Decode stage
            -- unless we are forwarding :)
            i_RS1 => driver_driver_raw.RS1, -- mem_driver_buf.RS1
            i_RS2 => driver_driver_raw.RS2, -- mem_driver_buf.RS2
            i_RD  => s_RegWrAddr,
            i_WE  => s_RegWr,
            i_D   => s_RegWrData,
            o_DS1 => s_RS1Data,
            o_DS2 => s_RS2Data
        );


    s_ALUOperand1 <= driver_insn_buf.IPAddr when (driver_driver_buf.IPToALU = '1') else
                     driver_driver_buf.DS1  when (driver_driver_buf.IPToALU = '0') else
                     (others => '0');

    s_ALUOperand2 <= driver_driver_buf.Imm  when (driver_driver_buf.ALUSrc = '1')  else
                     driver_driver_buf.DS2  when (driver_driver_buf.ALUSrc = '0')  else
                     (others => '0');

    SWCPU_ALU: entity work.alu
        port MAP(
            i_A     => s_RealALUOperand1,
            i_B     => s_RealALUOperand2,
            i_ALUOp => alu_driver_raw.ALUOp,
            o_F     => alu_alu_raw.F,
            o_Co    => alu_alu_raw.Co
        );

    oALUOut <= alu_alu_raw.F;
    s_DMemAddr <= alu_alu_buf.F;


    -- NOTE: store instructions do not sign-extend
    s_DMemData <= std_logic_vector(resize(unsigned(alu_driver_buf.DS2(7  downto 0)), s_DMemData'length)) when (alu_driver_buf.LSWidth = work.RISCV_types.BYTE) else
                  std_logic_vector(resize(unsigned(alu_driver_buf.DS2(15 downto 0)), s_DMemData'length)) when (alu_driver_buf.LSWidth = work.RISCV_types.HALF) else
                  std_logic_vector(resize(unsigned(alu_driver_buf.DS2(31 downto 0)), s_DMemData'length)) when (alu_driver_buf.LSWidth = work.RISCV_types.WORD) else
                  (others => '0');

    s_DMemOutExtended <= std_logic_vector(resize(unsigned(mem_mem_buf.Data(7  downto 0)), s_DMemOutExtended'length)) when (alu_driver_buf.LSWidth = work.RISCV_types.BYTE and alu_driver_buf.SignExtend = '0') else
                         std_logic_vector(resize(  signed(mem_mem_buf.Data(7  downto 0)), s_DMemOutExtended'length)) when (alu_driver_buf.LSWidth = work.RISCV_types.BYTE and alu_driver_buf.SignExtend = '1') else
                         std_logic_vector(resize(unsigned(mem_mem_buf.Data(15 downto 0)), s_DMemOutExtended'length)) when (alu_driver_buf.LSWidth = work.RISCV_types.HALF and alu_driver_buf.SignExtend = '0') else
                         std_logic_vector(resize(  signed(mem_mem_buf.Data(15 downto 0)), s_DMemOutExtended'length)) when (alu_driver_buf.LSWidth = work.RISCV_types.HALF and alu_driver_buf.SignExtend = '1') else
                         std_logic_vector(resize(unsigned(mem_mem_buf.Data(31 downto 0)), s_DMemOutExtended'length)) when (alu_driver_buf.LSWidth = work.RISCV_types.WORD and alu_driver_buf.SignExtend = '0') else
                         std_logic_vector(resize(  signed(mem_mem_buf.Data(31 downto 0)), s_DMemOutExtended'length)) when (alu_driver_buf.LSWidth = work.RISCV_types.WORD and alu_driver_buf.SignExtend = '1') else
                         (others => '0');


    -----------------------------------------------------
    ---- Hardware Pipeline Scheduling
    -----------------------------------------------------

    -- FIXME: should it be alu_alu_raw or buf?
    -- FIXME: what width to use for DMemData/extended to ensure that the correct value is read?
    s_RealALUOperand1 <= alu_alu_buf.F when (s_ForwardALUToALUOperand1 = '1' and s_ForwardMemToALUOperand1 = '0') else
                         s_DMemData    when (s_ForwardALUToALUOperand1 = '0' and s_ForwardMemToALUOperand1 = '1') else
                         s_ALUOperand1;

    -- FIXME: should it be alu_alu_raw or buf?
    -- FIXME: what width to use for DMemData/extended to ensure that the correct value is read?
    s_RealALUOperand2 <= alu_alu_buf.F when (s_ForwardALUToALUOperand2 = '1' and s_ForwardMemToALUOperand2 = '0') else
                         s_DMemData    when (s_ForwardALUToALUOperand2 = '0' and s_ForwardMemToALUOperand2 = '1') else
                         s_ALUOperand2;
        

    s_IsLoad <= '1' when (driver_driver_buf.LSWidth /= 0) else
                '0';

    HWCPU_HMU: entity work.hmu
        port MAP(
            i_MaskStall    => s_Branch,

            i_InsnRS1      => driver_driver_raw.RS1,
            i_InsnRS2      => driver_driver_raw.RS2,

            i_DriverRS1    => driver_driver_buf.RS1,
            i_DriverRS2    => driver_driver_buf.RS2,
            i_DriverRD     => driver_driver_buf.RD,
            i_DriverIsLoad => s_IsLoad,

            i_ALURD        => alu_driver_raw.RD,

            i_BranchMode   => mem_driver_buf.BGUOp,
            i_Branch       => s_Branch,
            i_IsBranch     => mem_driver_buf.Isbranch,

            o_Break        => s_IPBreak,
            o_InsnFlush    => insn_Flush,
            o_InsnStall    => insn_Stall,
            o_DriverFlush  => driver_Flush,
            o_DriverStall  => driver_Stall
        );

    HWCPU_DFU: entity work.dfu
        port MAP(
            i_InsnRS1     => driver_driver_raw.RS1, -- FIXME:
            i_InsnRS2     => driver_driver_raw.RS2, -- FIXME: how to connect this to insn

            i_DriverRS1   => driver_driver_buf.RS1,
            i_DriverRS2   => driver_driver_buf.RS2,

            i_ALURS1      => alu_driver_buf.RS1,
            i_ALURS2      => alu_driver_buf.RS2,
            i_ALURegWrite => alu_driver_buf.RegWrite,

            i_MemRD       => mem_driver_buf.RD,
            i_MemRS1      => mem_driver_buf.RS1,
            i_MemRS2      => mem_driver_buf.RS2,
            i_MemRegWrite => mem_driver_buf.RegWrite,

            i_BranchMode   => mem_driver_buf.BGUOp,
            i_Branch       => s_Branch,
            i_IsBranch     => mem_driver_buf.Isbranch,

            o_ForwardALUToALUOperand1 => s_ForwardALUToALUOperand1,
            o_ForwardALUToALUOperand2 => s_ForwardALUToALUOperand2,
            o_ForwardMemToALUOperand1 => s_ForwardMemToALUOperand1,
            o_ForwardMemToALUOperand2 => s_ForwardMemToALUOperand2,
            o_ForwardMemToDriverRS1   => s_ForwardMemToDriverRS1,
            o_ForwardMemToDriverRS2   => s_ForwardMemToDriverRS2,
            o_ForwardALUToDriverRS1   => s_ForwardALUToDriverRS1,
            o_ForwardALUToDriverRS2   => s_ForwardALUToDriverRS2
        );

    -----------------------------------------------------

end structure;

