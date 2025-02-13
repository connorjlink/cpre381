-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- decoder.vhd
-- DESCRIPTION: This file contains an implementation of a basic RISC-V frontend.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_types.all;

entity decoder is
    port(
        i_CLK    : in  std_logic;
        i_RST    : in  std_logic;
        i_Insn   : in  std_logic_vector(31 downto 0);
        o_Opcode : out std_logic_vector(6 downto 0);
        o_RD     : out std_logic_vector(4 downto 0);
        o_RS1    : out std_logic_vector(4 downto 0);
        o_RS2    : out std_logic_vector(4 downto 0);
        o_Func3  : out std_logic_vector(2 downto 0);
        o_Func7  : out std_logic_vector(6 downto 0);
        o_iImm   : out std_logic_vector(11 downto 0);
        o_sImm   : out std_logic_vector(11 downto 0);
        o_bImm   : out std_logic_vector(12 downto 0);
        o_uImm   : out std_logic_vector(31 downto 12);
        o_jImm   : out std_logic_vector(20 downto 0);
        o_hImm   : out std_logic_vector(4 downto 0)
    );
end decoder;

architecture dataflow of decoder is
begin

    o_Opcode <= i_Insn(6 downto 0);

    o_RD  <= i_Insn(11 downto 7);
    o_RS1 <= i_Insn(19 downto 15);
    o_RS2 <= i_Insn(24 downto 20);

    -- shamt field is in the same position as RS2
    o_hImm <= i_Insn(24 downto 20);

    o_Func3 <= i_Insn(14 downto 12);

    o_Func7 <= i_Insn(31 downto 25);

    o_iImm <= i_Insn(31 downto 20);

    o_sImm(11 downto 5) <= i_Insn(31 downto 25);
    o_sImm(4 downto 0)  <= i_Insn(11 downto 7);

    o_bImm(12)          <= i_Insn(31);
    o_bImm(11)          <= i_insn(7);
    o_bImm(10 downto 5) <= i_Insn(30 downto 25);
    o_bImm(4 downto 1)  <= i_Insn(11 downto 8);
    o_bImm(0)           <= '0';

    o_uImm <= i_insn(31 downto 12);

    o_jImm(20)           <= i_Insn(31);
    o_jImm(19 downto 12) <= i_Insn(19 downto 12);
    o_jImm(11)           <= i_Insn(20);
    o_jImm(10 downto 1)  <= i_Insn(30 downto 21);
    o_jImm(0)            <= '0';
    
end dataflow;
