-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- RISCV_Processor.vhd
-- DESCRIPTION: This file contains a skeleton of a software-scheduled 
-- pipelined RISCV_Processor implementation.

-- 01.29.2019 by H3::Design created.
-- 02.11.2025 by Connor J. Link authored RISC-V implementation.
-- 02.16.2025 by Connor J. Link authored 5-stage pipeline upgrade.
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
signal s_DriverRS1Data : std_logic_vector(31 downto 0);
signal s_RS2Data : std_logic_vector(31 downto 0);
signal s_DriverRS2Data : std_logic_vector(31 downto 0);

-- Signal to hold the ALU inputs and outputs
signal s_ALUOperand1 : std_logic_vector(31 downto 0);
signal s_RealALUOperand1 : std_logic_vector(31 downto 0);
signal s_ALUOperand2 : std_logic_vector(31 downto 0);
signal s_RealALUOperand2 : std_logic_vector(31 downto 0);

-- Signals to handle the output of the BGU
signal s_BranchTaken : std_logic;
signal s_BranchNotTaken : std_logic;

-- Signal to hold the modified clock
signal nCLK  : std_logic;

-- Signals to hold the computed memory instruction address input to the IP
signal s_BranchTakenAddr : std_logic_vector(31 downto 0);

-- Signal to output the contents of the instruction pointer
signal s_IPAddr : std_logic_vector(31 downto 0);
signal s_IPBreak : std_logic;
signal s_DriverIsLoad : std_logic;
signal s_ALUIsLoad : std_logic;

----------------------------------------------------------------------------------
---- Pipeline Data Signals
---- NOTE: the two identifiers are not the source and destination connections
---- The first is the source of the pipeline register, and the second is the stage
---- operating the pool of signals at hand.
----
---- Thus, EXMEM_IF_raw are the `input` signals to the pipeline register after the ALU
---- stage driven by the instruction register (so IPAddr, Insn, etc.)
----------------------------------------------------------------------------------
signal IFID_IF_raw,   IFID_IF_buf   : work.RISCV_types.insn_record_t;

signal IDEX_IF_raw,   IDEX_IF_buf   : work.RISCV_types.insn_record_t;
signal IDEX_ID_raw,   IDEX_ID_buf   : work.RISCV_types.driver_record_t;

signal EXMEM_IF_raw,  EXMEM_IF_buf  : work.RISCV_types.insn_record_t;
signal EXMEM_ID_raw,  EXMEM_ID_buf  : work.RISCV_types.driver_record_t;
signal EXMEM_EX_raw,  EXMEM_EX_buf  : work.RISCV_types.alu_record_t;

signal MEMWB_IF_raw,  MEMWB_IF_buf  : work.RISCV_types.insn_record_t;
signal MEMWB_ID_raw,  MEMWB_ID_buf  : work.RISCV_types.driver_record_t;
signal MEMWB_EX_raw,  MEMWB_EX_buf  : work.RISCV_types.alu_record_t;
signal MEMWB_MEM_raw, MEMWB_MEM_buf : work.RISCV_types.mem_record_t;


signal IFID_Stall,  IFID_Flush  : std_logic := '0';
signal IDEX_Stall,  IDEX_Flush  : std_logic := '0';
signal EXMEM_Stall, EXMEM_Flush : std_logic := '0';
signal MEMWB_Stall, MEMWB_Flush : std_logic := '0';
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
---- Pipeline Data Signals
----------------------------------------------------------------------------------
signal s_ForwardALUToALUOperand1, s_ForwardALUToALUOperand2, s_ForwardMemToALUOperand1, s_ForwardMemToALUOperand2 : std_logic := '0';
signal s_ForwardMemToDriverRS1,   s_ForwardMemToDriverRS2,   s_ForwardALUToDriverRS1,   s_ForwardALUToDriverRS2   : std_logic := '0';
----------------------------------------------------------------------------------


begin

    s_Ovfl <= '0'; -- RISC-V does not support overflow-checked arithmetic.
    
    nCLK <= not iCLK;

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
            clk  => iCLK,
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
            clk  => nCLK,
            addr => s_DMemAddr(11 downto 2),
            data => s_DMemData,
            we   => s_DMemWr,
            q    => s_DMemOut
        );

    s_DMemWr <= EXMEM_ID_buf.MemWrite;
    MEMWB_MEM_raw.Data <= s_DMemOut;

    -- IMPLEMENTATION STARTS HERE

    -----------------------------------------------------
    ---- Instruction -> Driver stage register(s)
    -----------------------------------------------------

    SWCPU_Insn_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => IFID_Stall,
            i_Flush => IFID_Flush,
        
            i_Signals => IFID_IF_raw,
            o_Signals => IFID_IF_buf
        );

    IDEX_IF_raw <= IFID_IF_buf;
        
    -----------------------------------------------------


    -----------------------------------------------------
    ---- Driver -> ALU stage register(s)
    -----------------------------------------------------

    SWCPU_Driver_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => IDEX_Stall,
            i_Flush => IDEX_Flush,
        
            i_Signals => IDEX_IF_raw,
            o_Signals => IDEX_IF_buf
        );

    SWCPU_Driver_DR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => IDEX_Stall,
            i_Flush => IDEX_Flush,
        
            i_Signals => IDEX_ID_raw,
            o_Signals => IDEX_ID_buf
        );

    EXMEM_IF_raw <= IDEX_IF_buf;
    EXMEM_ID_raw <= IDEX_ID_buf;

    -----------------------------------------------------


    -----------------------------------------------------
    ---- ALU -> Memory stage register(s)
    -----------------------------------------------------

    SWCPU_ALU_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => EXMEM_Stall,
            i_Flush => EXMEM_Flush,
        
            i_Signals => EXMEM_IF_raw,
            o_Signals => EXMEM_IF_buf
        );

    SWCPU_ALU_DR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => EXMEM_Stall,
            i_Flush => EXMEM_Flush,
        
            i_Signals => EXMEM_ID_raw,
            o_Signals => EXMEM_ID_buf
        );

    SWCPU_ALU_AR: entity work.reg_alu
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => EXMEM_Stall,
            i_Flush => EXMEM_Flush,
        
            i_Signals => EXMEM_EX_raw,
            o_Signals => EXMEM_EX_buf
        );


    MEMWB_IF_raw <= EXMEM_IF_buf;
    MEMWB_ID_raw <= EXMEM_ID_buf;
    MEMWB_EX_raw <= EXMEM_EX_buf;

    -----------------------------------------------------


    -----------------------------------------------------
    ---- Memory -> Register File stage register(s)
    -----------------------------------------------------

    SWCPU_Mem_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => MEMWB_Stall,
            i_Flush => MEMWB_Flush,
        
            i_Signals => MEMWB_IF_raw,
            o_Signals => MEMWB_IF_buf
        );

    SWCPU_Mem_DR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => MEMWB_Stall,
            i_Flush => MEMWB_Flush,
        
            i_Signals => MEMWB_ID_raw,
            o_Signals => MEMWB_ID_buf
        );

    SWCPU_Mem_AR: entity work.reg_alu
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => MEMWB_Stall,
            i_Flush => MEMWB_Flush,
        
            i_Signals => MEMWB_EX_raw,
            o_Signals => MEMWB_EX_buf
        ); 
    

    SWCPU_Mem_MR: entity work.reg_mem
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_Stall => MEMWB_Stall,
            i_Flush => MEMWB_Flush,
        
            i_Signals => MEMWB_MEM_raw,
            o_Signals => MEMWB_MEM_buf
        );

    -----------------------------------------------------


    -- ALU or MEM stage here for inputs?
    -- buf or raw?
    s_BranchTakenAddr <= std_logic_vector(signed(IDEX_IF_buf.IPAddr) + signed(IDEX_ID_buf.Imm)) when (IDEX_ID_buf.BranchMode = work.RISCV_types.JAL_OR_BCC) else
                         std_logic_vector(signed(IDEX_ID_buf.DS1)  + signed(IDEX_ID_buf.Imm)) when (IDEX_ID_buf.BranchMode = work.RISCV_types.JALR)       else 
                         (others => '0');

    SWCPU_IP: entity work.ip
        generic MAP(
            ResetAddress => 32x"00400000"
        )
        port MAP(
            i_CLK        => iCLK, -- TODO: i_CLK or nCLK
            i_RST        => iRST,
            i_Stall      => s_IPBreak,
            i_Load       => s_BranchTaken,
            i_Addr       => s_BranchTakenAddr,
            -- BELOW: might be 1 pipeline stage ahead (one cycle off)
            i_nInc2_Inc4 => '1', -- FIXME:IDEX_ID_buf.IPStride, -- FIXME: is this too late in the pipeline to decide how far to stride each instruction?
            o_Addr       => s_IPAddr,
            o_LinkAddr   => s_NextInstAddr 
        );
    IFID_IF_raw.IPAddr   <= s_IPAddr;
    IFID_IF_raw.LinkAddr <= s_NextInstAddr;
    IFID_IF_raw.Insn     <= s_Inst;


    --MEMWB_ID_buf.DS1, --s_RS1Data,
    --MEMWB_ID_buf.DS2, --s_RS2Data,
    --MEMWB_ID_buf.BGUOp, --s_dBGUOp,
    SWCPU_BGU: entity work.bgu
        port MAP(
            i_CLK    => iCLK,
            i_DS1    => IDEX_ID_buf.DS1,
            i_DS2    => IDEX_ID_buf.DS2,
            i_BGUOp  => IDEX_ID_buf.BGUOp,
            o_Branch => s_BranchTaken
            --o_BranchNotTaken => s_BranchNotTaken
        );


    SWCPU_Driver: entity work.driver
        port MAP(
            i_CLK        => iCLK,
            i_RST        => iRST,
            i_Insn       => IDEX_IF_raw.Insn, -- s_Inst,
            o_MemWrite   => IDEX_ID_raw.MemWrite, -- s_DMemWr
            o_RegWrite   => IDEX_ID_raw.RegWrite, -- s_RegWr,
            o_RFSrc      => IDEX_ID_raw.RFSrc,
            o_ALUSrc     => IDEX_ID_raw.ALUSrc,
            o_ALUOp      => IDEX_ID_raw.ALUOp,
            o_BGUOp      => IDEX_ID_raw.BGUOp,
            o_LSWidth    => IDEX_ID_raw.LSWidth,
            o_RD         => IDEX_ID_raw.RD, -- s_RegWrAddr,
            o_RS1        => IDEX_ID_raw.RS1,
            o_RS2        => IDEX_ID_raw.RS2, 
            o_Imm        => IDEX_ID_raw.Imm,
            o_BranchMode => IDEX_ID_raw.BranchMode,
            o_Break      => IDEX_ID_raw.Break,
            o_IsBranch   => IDEX_ID_raw.IsBranch,
            o_IPStride   => IDEX_ID_raw.IPStride,
            o_SignExtend => IDEX_ID_raw.SignExtend,
            o_IPToALU    => IDEX_ID_raw.IPToALU
        );

    -- TODO: what is the best way of detecting break?
    s_Halt <= (MEMWB_ID_buf.Break and EXMEM_ID_buf.Break);

    -- FIXME: should it be EXMEM_EX_raw or buf?
    -- FIXME: what width to use for DMemData/extended to ensure that the correct value is read? 

    s_DriverRS1Data <= EXMEM_EX_raw.F when (s_ForwardALUToDriverRS1 = '1' and s_ForwardMemToDriverRS1 = '0') else
                       MEMWB_EX_buf.F when (s_ForwardALUToDriverRS1 = '0' and s_ForwardMemToDriverRS1 = '1') else
                       s_RS1Data;

    s_DriverRS2Data <= EXMEM_EX_raw.F when (s_ForwardALUToDriverRS2 = '1' and s_ForwardMemToDriverRS2 = '0') else
                       MEMWB_EX_buf.F when (s_ForwardALUToDriverRS2 = '0' and s_ForwardMemToDriverRS2 = '1') else
                       s_RS2Data;

    IDEX_ID_raw.DS1 <= s_DriverRS1Data;
    IDEX_ID_raw.DS2 <= s_DriverRS2Data;



    s_RegWrData <= s_DMemOutExtended     when (MEMWB_ID_buf.RFSrc = work.RISCV_types.FROM_RAM)    else 
                   MEMWB_EX_buf.F        when (MEMWB_ID_buf.RFSrc = work.RISCV_types.FROM_ALU)    else 
                   MEMWB_IF_buf.LinkAddr when (MEMWB_ID_buf.RFSrc = work.RISCV_types.FROM_NEXTIP) else
                   MEMWB_ID_buf.Imm      when (MEMWB_ID_buf.RFSrc = work.RISCV_types.FROM_IMM)    else
                   (others => '0');

    s_RegWr <= MEMWB_ID_buf.RegWrite;
    s_RegWrAddr <= MEMWB_ID_buf.RD;

    SWCPU_RegisterFile: entity work.regfile
        port MAP(
            i_CLK => nCLK, -- TODO:  nCLK/iCLK
            i_RST => iRST,
            -- following, I guess that register reads HAVE to happen in the Decode stage
            -- unless forwarding
            i_RS1 => IDEX_ID_raw.RS1, -- MEMWB_ID_buf.RS1
            i_RS2 => IDEX_ID_raw.RS2, -- MEMWB_ID_buf.RS2
            i_RD  => s_RegWrAddr,
            i_WE  => s_RegWr,
            i_D   => s_RegWrData,
            o_DS1 => s_RS1Data,
            o_DS2 => s_RS2Data
        );


    s_ALUOperand1 <= IDEX_IF_buf.IPAddr when (IDEX_ID_buf.IPToALU = '1') else
                     IDEX_ID_buf.DS1    when (IDEX_ID_buf.IPToALU = '0') else
                     (others => '0');

    s_ALUOperand2 <= IDEX_ID_buf.Imm  when (IDEX_ID_buf.ALUSrc = '1')  else
                     IDEX_ID_buf.DS2  when (IDEX_ID_buf.ALUSrc = '0')  else
                     (others => '0');

    SWCPU_ALU: entity work.alu
        port MAP(
            i_A     => s_RealALUOperand1,
            i_B     => s_RealALUOperand2,
            i_ALUOp => EXMEM_ID_raw.ALUOp,
            o_F     => EXMEM_EX_raw.F,
            o_Co    => EXMEM_EX_raw.Co
        );

    oALUOut <= EXMEM_EX_raw.F;
    s_DMemAddr <= EXMEM_EX_buf.F;


    -- NOTE: store instructions do not sign-extend
    s_DMemData <= std_logic_vector(resize(unsigned(EXMEM_ID_buf.DS2(7  downto 0)), s_DMemData'length)) when (EXMEM_ID_buf.LSWidth = work.RISCV_types.BYTE) else
                  std_logic_vector(resize(unsigned(EXMEM_ID_buf.DS2(15 downto 0)), s_DMemData'length)) when (EXMEM_ID_buf.LSWidth = work.RISCV_types.HALF) else
                  std_logic_vector(resize(unsigned(EXMEM_ID_buf.DS2(31 downto 0)), s_DMemData'length)) when (EXMEM_ID_buf.LSWidth = work.RISCV_types.WORD) else
                  (others => '0');

    s_DMemOutExtended <= std_logic_vector(resize(unsigned(MEMWB_MEM_buf.Data(7  downto 0)), s_DMemOutExtended'length)) when (EXMEM_ID_buf.LSWidth = work.RISCV_types.BYTE and EXMEM_ID_buf.SignExtend = '0') else
                         std_logic_vector(resize(  signed(MEMWB_MEM_buf.Data(7  downto 0)), s_DMemOutExtended'length)) when (EXMEM_ID_buf.LSWidth = work.RISCV_types.BYTE and EXMEM_ID_buf.SignExtend = '1') else
                         std_logic_vector(resize(unsigned(MEMWB_MEM_buf.Data(15 downto 0)), s_DMemOutExtended'length)) when (EXMEM_ID_buf.LSWidth = work.RISCV_types.HALF and EXMEM_ID_buf.SignExtend = '0') else
                         std_logic_vector(resize(  signed(MEMWB_MEM_buf.Data(15 downto 0)), s_DMemOutExtended'length)) when (EXMEM_ID_buf.LSWidth = work.RISCV_types.HALF and EXMEM_ID_buf.SignExtend = '1') else
                         std_logic_vector(resize(unsigned(MEMWB_MEM_buf.Data(31 downto 0)), s_DMemOutExtended'length)) when (EXMEM_ID_buf.LSWidth = work.RISCV_types.WORD and EXMEM_ID_buf.SignExtend = '0') else
                         std_logic_vector(resize(  signed(MEMWB_MEM_buf.Data(31 downto 0)), s_DMemOutExtended'length)) when (EXMEM_ID_buf.LSWidth = work.RISCV_types.WORD and EXMEM_ID_buf.SignExtend = '1') else
                         (others => '0');


    -----------------------------------------------------
    ---- Hardware Pipeline Scheduling
    -----------------------------------------------------

    -- FIXME: should it be EXMEM_EX_raw or buf?
    -- FIXME: what width to use for DMemData/extended to ensure that the correct value is read?
    s_RealALUOperand1 <= EXMEM_EX_buf.F when (s_ForwardALUToALUOperand1 = '1' and s_ForwardMemToALUOperand1 = '0') else
                         MEMWB_EX_buf.F when (s_ForwardALUToALUOperand1 = '0' and s_ForwardMemToALUOperand1 = '1') else
                         s_ALUOperand1;

    -- FIXME: should it be EXMEM_EX_raw or buf?
    -- FIXME: what width to use for DMemData/extended to ensure that the correct value is read?
    s_RealALUOperand2 <= EXMEM_EX_buf.F when (s_ForwardALUToALUOperand2 = '1' and s_ForwardMemToALUOperand2 = '0') else
                         MEMWB_EX_buf.F when (s_ForwardALUToALUOperand2 = '0' and s_ForwardMemToALUOperand2 = '1') else
                         s_ALUOperand2;
        

    -- FIXME: maybe need to do some checking with RegWrite/MemWRite to distinguish loads and stores
    s_DriverIsLoad <= '1' when (IDEX_ID_raw.LSWidth /= 0) else
                      '0';

    s_ALUIsLoad <= '1' when (EXMEM_ID_raw.LSWidth /= 0) else
                   '0';

    HWCPU_HMU: entity work.hmu
        port MAP(
            --i_CLK          => iCLK,
            --i_MaskFlush    => s_BranchTaken,

            i_InsnRS1      => IDEX_ID_raw.RS1,
            i_InsnRS2      => IDEX_ID_raw.RS2,

            i_DriverRS1    => IDEX_ID_buf.RS1,
            i_DriverRS2    => IDEX_ID_buf.RS2,
            i_DriverRD     => IDEX_ID_buf.RD,
            i_DriverIsLoad => s_DriverIsLoad,

            i_ALURD        => EXMEM_ID_buf.RD,
            i_ALUIsLoad    => s_ALUIsLoad,

            -- TODO: are these raw or buf
            i_BranchMode   => IDEX_ID_buf.BGUOp, --MEMWB_ID_buf.BGUOp,
            i_Branch       => s_BranchTaken,
            i_IsBranch     => IDEX_ID_buf.IsBranch, --MEMWB_ID_buf.Isbranch,

            o_Break        => s_IPBreak,
            o_InsnFlush    => IFID_Flush,
            o_InsnStall    => IFID_Stall,
            o_DriverFlush  => IDEX_Flush,
            o_DriverStall  => IDEX_Stall
        );

    HWCPU_DFU: entity work.dfu
        port MAP(
            i_InsnRS1     => IDEX_ID_raw.RS1, -- FIXME:
            i_InsnRS2     => IDEX_ID_raw.RS2, -- FIXME: how to connect this to insn

            i_DriverRS1   => IDEX_ID_buf.RS1,
            i_DriverRS2   => IDEX_ID_buf.RS2,

            i_ALURD       => EXMEM_ID_buf.RD,
            i_ALURS1      => EXMEM_ID_buf.RS1,
            i_ALURS2      => EXMEM_ID_buf.RS2,
            i_ALURegWrite => EXMEM_ID_buf.RegWrite,

            i_MemRD       => MEMWB_ID_buf.RD,
            i_MemRS1      => MEMWB_ID_buf.RS1,
            i_MemRS2      => MEMWB_ID_buf.RS2,
            i_MemRegWrite => MEMWB_ID_buf.RegWrite,

            i_BranchMode   => IDEX_ID_buf.BGUOp,
            i_Branch       => s_BranchTaken,
            i_IsBranch     => IDEX_ID_buf.Isbranch,

            
            o_ForwardALUToALUOperand1 => s_ForwardALUToALUOperand1,
            o_ForwardALUToALUOperand2 => s_ForwardALUToALUOperand2,
            o_ForwardMemToALUOperand1 => s_ForwardMemToALUOperand1,
            o_ForwardMemToALUOperand2 => s_ForwardMemToALUOperand2,

            -- TODO:
            o_ForwardMemToDriverRS1   => s_ForwardMemToDriverRS1,
            o_ForwardMemToDriverRS2   => s_ForwardMemToDriverRS2,
            o_ForwardALUToDriverRS1   => s_ForwardALUToDriverRS1,
            o_ForwardALUToDriverRS2   => s_ForwardALUToDriverRS2
        );

    -----------------------------------------------------

end structure;

