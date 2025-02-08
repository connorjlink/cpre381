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
use work.my_enums.all;
use work.my_records.all;

-- TODO LIST:
-- pipeline stalling

entity software_cpu is
    port(i_CLK : in std_logic;
         i_RST : in std_logic);
end software_cpu;

architecture mixed of software_cpu is

-- Instruction -> Driver register signals
signal p_oInsn   : my_records.controls_t;
signal p_iDriver : my_records.controls_t;

-- Driver -> ALU register signals
signal p_oDriver : my_records.controls_t;
signal p_iALU    : my_records.controls_t;

-- ALU -> Memory register signals
signal p_oALU : my_records.controls_t;
signal p_iMem : my_records.controls_t;

-- Memory -> RF register signals
signal p_oMem : my_records.controls_t;
signal p_iReg : my_records.controls_t;


-- Signals to support gated clock for breaking off execution
signal s_Break : std_logic;
signal g_CLK   : std_logic;

begin

    g_CLK <= i_CLK and not s_Break;

    SoftwareCPU_InstructionPointer: ip
        generic MAP(
            ResetAddress => 32x"0" -- overriding this for testing purposes
        );
        port MAP(
            i_CLK => g_CLK,
            i_RST => i_RST,

            i_Load       =>
            i_Addr       => 
            i_nInc2_Inc4 =>
            i_Stall      => '0',
            o_Addr       => p_oInsn.o_IPAddr,
            o_LinkAddr   =>
        );

    SoftwareCPU_InstructionMemory: mem
        generic MAP(
            DATA_WIDTH => 32,
            ADDR_WIDTH => 10
        )
        port MAP(
            clk  => g_CLK,
            addr => p_oInsn.o_IPAddr(11 downto 2), -- divide instruction address by four since each address is one word
            data => (others => '0'), -- ROM
            we   => '0',
            q    => p_oInsn.o_Insn
        );

    SoftwareCPU_InstructionRegister: reg_pipeline
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0',
            
            i_Signals => p_oInsn,
            o_Signals => p_iDriver,
        );

    SoftwareCPU_Driver: driver
        port MAP(
            i_CLK => g_CLK,
            i_RST => i_RST,

            i_Signals => p_iDriver,
            o_Signals => p_oDriver,
        );

    SoftwareCPU_DriverRegister: reg_pipeline
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0',

            i_Signals => p_oDriver,
            o_Signals => p_iALU
        );

    SoftwareCPU_ALU: alu
        port MAP(
            i_A     =>
            i_B     =>
            i_ALUOp =>
            o_F     =>
            o_Co    =>
        );

    SoftwareCPU_ALURegister: reg_pipeline
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0',

            i_Signals => p_oALU,
            o_Signals => p_iMem,
        );

    SoftwareCPU_DataMemory: mem
        generic MAP(
            DATA_WIDTH => 32,
            ADDR_WIDTH => 10
        )
        port MAP(
            clk  => g_CLK,
            addr => 
            data =>
            we   =>
            q    =>
        );

    SoftwareCPU_MemRegister: reg_pipeline
        port MAP(
            i_CLK   => g_CLK,
            i_RST   => i_RST,
            i_STALL => '0',

            i_Signals => p_oMem,
            o_Signals => p_iReg
        );

    SoftwareCPU_RegisterFile: regfile
        port MAP(
            i_CLK => g_nCLK,
            i_RST => i_RST,
            i_RS1 =>
            i_RS2 =>
            i_RD  =>
            i_WE  =>
            i_D   =>
            o_DS1 =>
            o_DS2 =>
        );

end software_cpu;