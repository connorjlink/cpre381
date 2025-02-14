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


entity SW_MIPS_Processor is
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
end SW_MIPS_Processor;

architecture structure of SW_MIPS_Processor is

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
signal s_mDataScaled : std_logic_vector(31 downto 0);

-- Signals to hold the intermediate outputs from the register file
signal s_DS1 : std_logic_vector(31 downto 0);
signal s_DS2 : std_logic_vector(31 downto 0);

-- Signal to hold the ALU inputs and outputs
signal s_aluA : std_logic_vector(31 downto 0);
signal s_aluB : std_logic_vector(31 downto 0);
signal s_aluF : std_logic_vector(31 downto 0);
signal s_oCo  : std_logic;

-- Signals to hold the control lines from the driver
signal s_dRFSrc      : natural; -- 0 = ALU, 1 = memory, 2 = IP+4
signal s_dALUSrc     : std_logic;
signal s_dALUOp      : natural;
signal s_dBGUOp      : natural;
signal s_dLSWidth    : natural;
signal s_dRS1        : std_logic_vector(4 downto 0);
signal s_dRS2        : std_logic_vector(4 downto 0);
signal s_dImm        : std_logic_vector(31 downto 0);
signal s_dBranchMode : natural;
signal s_dnInc2_Inc4 : std_logic; 
signal s_dnZero_Sign : std_logic;
signal s_dIPToALU    : std_logic;

-- Signals to handle the output of the BGU
signal s_Branch : std_logic;

-- Signal to hold the modified clock
signal s_gCLK  : std_logic;
signal s_ngCLK : std_logic;

-- Signals to hold the computed memory instruction address input to the IP
signal s_BranchAddr : std_logic_vector(31 downto 0);

-- Signal to output the contents of the instruction pointer
signal s_IPAddr : std_logic_vector(31 downto 0);


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


signal insn_Stall,   insn_Flush   : std_logic;
signal driver_Stall, driver_Flush : std_logic;
signal alu_Stall,    alu_Flush    : std_logic;
signal mem_Stall,    mem_Flush    : std_logic;
----------------------------------------------------------------------------------


begin

    s_Ovfl <= '0'; -- RISC-V does not support overflow-checked arithmetic.
    
    s_gCLK  <= (not s_Halt) and iCLK;
    s_ngCLK <= not s_gCLK;

    s_BranchAddr <= std_logic_vector(signed(mem_insn_buf.IPAddr) + signed(mem_driver_buf.Imm)) when (mem_driver_buf.BranchMode = work.RISCV_types.JAL)  else
                    std_logic_vector(signed(mem_driver_buf.DS1)  + signed(mem_driver_buf.Imm)) when (mem_driver_buf.BranchMode = work.RISCV_types.JALR) else 
                    std_logic_vector(signed(mem_insn_buf.IPAddr) + signed(mem_driver_buf.Imm)) when (mem_driver_buf.BranchMode = work.RISCV_types.BCC)  else
                    (others => '0');

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

    -- IMPLEMENTATION STARTS HERE

    -----------------------------------------------------
    ---- Instruction -> Driver stage register(s)
    -----------------------------------------------------

    SoftwareCPU_Insn_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => insn_Stall,
            i_FLUSH => insn_Flush,
        
            i_Signals => insn_insn_raw,
            o_Signals => insn_insn_buf
        );

    driver_insn_raw <= insn_insn_buf;
        
    -----------------------------------------------------


    -----------------------------------------------------
    ---- Driver -> ALU stage register(s)
    -----------------------------------------------------

    SoftwareCPU_Driver_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => driver_Stall,
            i_FLUSH => driver_Flush,
        
            i_Signals => driver_insn_raw,
            o_Signals => driver_insn_buf
        );

    SoftwareCPU_Driver_DR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => driver_Stall,
            i_FLUSH => driver_Flush,
        
            i_Signals => driver_driver_raw,
            o_Signals => driver_driver_buf
        );

    alu_insn_raw   <= driver_insn_buf;
    alu_driver_raw <= driver_driver_buf;

    -----------------------------------------------------


    -----------------------------------------------------
    ---- ALU -> Memory stage register(s)
    -----------------------------------------------------

    SoftwareCPU_ALU_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => alu_Stall,
            i_FLUSH => alu_Flush,
        
            i_Signals => alu_insn_raw,
            o_Signals => alu_insn_buf
        );

    SoftwareCPU_ALU_DR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => alu_Stall,
            i_FLUSH => alu_Flush,
        
            i_Signals => alu_driver_raw,
            o_Signals => alu_driver_buf
        );

    SoftwareCPU_ALU_AR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => alu_Stall,
            i_FLUSH => alu_Flush,
        
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

    SoftwareCPU_Mem_IR: entity work.reg_insn
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => mem_Stall,
            i_FLUSH => mem_Flush,
        
            i_Signals => mem_insn_raw,
            o_Signals => mem_insn_buf
        );

    SoftwareCPU_Mem_DR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => mem_Stall,
            i_FLUSH => mem_Flush,
        
            i_Signals => mem_driver_raw,
            o_Signals => mem_driver_buf
        );

    SoftwareCPU_Mem_AR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => mem_Stall,
            i_FLUSH => mem_Flush,
        
            i_Signals => mem_alu_raw,
            o_Signals => mem_alu_buf
        ); 
    

    SoftwareCPU_Mem_MR: entity work.reg_driver
        port MAP(
            i_CLK => iCLK,
            i_RST => iRST,
            i_STALL => mem_Stall,
            i_FLUSH => mem_Flush,
        
            i_Signals => mem_mem_raw,
            o_Signals => mem_mem_buf
        );

    -----------------------------------------------------


    SoftwareCPU_IP: entity work.ip
        generic MAP(
            ResetAddress => 32x"0"
        )
        port MAP(
            i_CLK        => iCLK, -- TODO: i_CLK or s_gCLK
            i_RST        => iRST,
            i_Stall      => insn_Stall, -- FIXME:
            i_Load       => s_Branch,
            i_Addr       => s_BranchAddr, -- FIXME:
            -- BELOW: might be 1 pipeline stage ahead (one cycle off)
            i_nInc2_Inc4 => driver_driver_raw.nInc2_Inc4, -- FIXME: is this too late in the pipeline to decide how far to stride each instruction?
            o_Addr       => s_IPAddr,
            -- BELOW:replaced from s_LinkAddr, for it represents the address to which to link should a jal/jalr take place
            o_LinkAddr   => s_NextInstAddr 
        );
    insn_insn_raw.IPAddr   <= s_IPAddr;
    insn_insn_raw.LinkAddr <= s_NextInstAddr;
    insn_insn_raw.Insn     <= s_Inst;


    SoftwareCPU_BGU: entity work.bgu
        port MAP(
            i_CLK    => s_gCLK,
            -- these signals might need to be hooked up to earlier in the pipeline
            -- the like the raw output from the driver or something in order to later forward ht evlaue that we n eed
            i_DS1    => mem_driver_buf.DS1, --s_DS1,
            i_DS2    => mem_driver_buf.DS2, --s_DS2,
            i_BGUOp  => mem_Driver_buf.BGUOp, --s_dBGUOp,
            o_Branch => s_Branch
        );


    SoftwareCPU_Driver: entity work.driver
        port MAP(
            i_CLK        => s_gCLK,
            i_RST        => iRST,
            i_Insn       => s_Inst,
            i_MaskStall  => '0', -- TODO: this should not affect this single cycle model
            o_MemWrite   => s_DMemWr,
            o_RegWrite   => s_RegWr,
            o_RFSrc      => s_dRFSrc,
            o_ALUSrc     => s_dALUSrc,
            o_ALUOp      => s_dALUOp,
            o_BGUOp      => s_dBGUOp,
            o_LSWidth    => s_dLSWidth,
            o_RD         => s_RegWrAddr,
            o_RS1        => s_dRS1,
            o_RS2        => s_dRS2, 
            o_Imm        => s_dImm,
            o_BranchMode => s_dBranchMode,
            o_Break      => s_Halt, -- FIXME: open
            o_IsBranch   => open,
            o_nInc2_Inc4 => s_dnInc2_Inc4,
            o_nZero_Sign => s_dnZero_Sign,
            o_IPToALU    => s_dIPToALU
        );


    SoftwareCPU_RegisterFile: entity work.regfile
        port MAP(
            i_CLK => s_ngCLK,
            --i_CLK => s_gCLK, -- needs to be written on the negedge
            i_RST => iRST,
            i_RS1 => s_dRS1,
            i_RS2 => s_dRS2,
            i_RD  => s_RegWrAddr,
            i_WE  => s_RegWr,
            i_D   => s_RegWrData,
            o_DS1 => s_DS1,
            o_DS2 => s_DS2
        );


    s_aluA <= driver_insn_buf.IPAddr when (driver_driver_buf.IPToALU = '1') else
              driver_driver_buf.DS1  when (driver_driver_buf.IPToALU = '0') else
              (others => '0');

    s_aluB <= driver_driver_buf.Imm when (driver_driver_buf.ALUSrc = '1') else
              driver_driver_buf.DS2 when (driver_driver_buf.ALUSrc = '0') else
              (others => '0');

    SoftwareCPU_ALU: entity work.alu
        port MAP(
            i_A     => s_aluA,
            i_B     => s_aluB,
            i_ALUOp => alu_alu_raw.ALUOp,
            o_F     => alu_alu_raw.F,
            o_Co    => alu_alu_raw.Co
        );

    oALUOut <= alu_alu_raw.F;
    s_DMemAddr <= alu_alu_raw.F;


    -- NOTE: store instructions do not sign-extend
    s_DMemData <= std_logic_vector(resize(unsigned(s_DS2(7  downto 0)), s_DMemData'length)) when (s_dLSWidth = work.RISCV_types.BYTE) else
                  std_logic_vector(resize(unsigned(s_DS2(15 downto 0)), s_DMemData'length)) when (s_dLSWidth = work.RISCV_types.HALF) else
                  std_logic_vector(resize(unsigned(s_DS2(31 downto 0)), s_DMemData'length)) when (s_dLSWidth = work.RISCV_types.WORD) else
                  (others => '0');

    s_mDataScaled <= std_logic_vector(resize(unsigned(s_DMemOut(7  downto 0)), s_mDataScaled'length)) when (s_dLSWidth = work.RISCV_types.BYTE and s_dnZero_Sign = '0') else
                     std_logic_vector(resize(  signed(s_DMemOut(7  downto 0)), s_mDataScaled'length)) when (s_dLSWidth = work.RISCV_types.BYTE and s_dnZero_Sign = '1') else
                     std_logic_vector(resize(unsigned(s_DMemOut(15 downto 0)), s_mDataScaled'length)) when (s_dLSWidth = work.RISCV_types.HALF and s_dnZero_Sign = '0') else
                     std_logic_vector(resize(  signed(s_DMemOut(15 downto 0)), s_mDataScaled'length)) when (s_dLSWidth = work.RISCV_types.HALF and s_dnZero_Sign = '1') else
                     std_logic_vector(resize(unsigned(s_DMemOut(31 downto 0)), s_mDataScaled'length)) when (s_dLSWidth = work.RISCV_types.WORD and s_dnZero_Sign = '0') else
                     std_logic_vector(resize(  signed(s_DMemOut(31 downto 0)), s_mDataScaled'length)) when (s_dLSWidth = work.RISCV_types.WORD and s_dnZero_Sign = '1') else
                     (others => '0');


    s_RegWrData <= s_mDataScaled  when (s_dRFSrc = work.RISCV_types.FROM_RAM)    else 
                   s_aluF         when (s_dRFSrc = work.RISCV_types.FROM_ALU)    else 
                   s_NextInstAddr when (s_dRFSrc = work.RISCV_types.FROM_NEXTIP) else
                   s_dImm         when (s_dRFSrc = work.RISCV_types.FROM_IMM)    else
                   (others => '0');

end structure;

