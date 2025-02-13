-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- bgu.vhd
-- DESCRIPTION: This file contains an implementation of a basic RISC-V branch generation unit.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.RISCV_types.all;

entity alu is
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
end alu;

architecture mixed of alu is

component addsub_N is
    generic(
        N : integer := 32
    );
    port(
        i_A        : in  std_logic_vector(N-1 downto 0);
        i_B        : in  std_logic_vector(N-1 downto 0);
        i_nAdd_Sub : in  std_logic;
        o_S        : out std_logic_vector(N-1 downto 0);
        o_Co       : out std_logic
    );
end component;

component xorg2 is
    port(
        i_A : in  std_logic;
        i_B : in  std_logic;
        o_F : out std_logic
    );
end component;

component org2 is
    port(
        i_A : in  std_logic;
        i_B : in  std_logic;
        o_F : out std_logic
    );
end component;

component andg2 is
    port(
        i_A : in  std_logic;
        i_B : in  std_logic;
        o_F : out std_logic
    );
end component;

-- Signals to hold the results of each logical unit
signal s_xorF : std_logic_vector(N-1 downto 0);
signal s_orF  : std_logic_vector(N-1 downto 0);
signal s_andF : std_logic_vector(N-1 downto 0);
signal s_addF : std_logic_vector(N-1 downto 0);
signal s_subF : std_logic_vector(N-1 downto 0);
signal s_sllF : std_logic_vector(N-1 downto 0);
signal s_srlF : std_logic_vector(N-1 downto 0);
signal s_sraF : std_logic_vector(N-1 downto 0);
signal s_sltF : std_logic_vector(N-1 downto 0);
signal s_sltuF : std_logic_vector(N-1 downto 0);

signal s_addCo : std_logic;
signal s_subCo : std_logic;

begin

    -- XOR Unit
    g_NBit_XOR: for i in 0 to N-1
    generate
        XORI: xorg2
            port MAP(
                i_A => i_A(i),
                i_B => i_B(i),
                o_F => s_xorF(i)
            );
    end generate g_NBit_XOR;

    -- OR Unit
    g_NBit_OR: for i in 0 to N-1
    generate
        ORI: org2
            port MAP(
                i_A => i_A(i),
                i_B => i_B(i),
                o_F => s_orF(i)
            );
    end generate g_NBit_OR;

    -- AND Unit
    g_NBit_AND: for i in 0 to N-1
    generate
        ANDI: andg2
            port MAP(
                i_A => i_A(i),
                i_B => i_B(i),
                o_F => s_andF(i)
            );
    end generate g_NBit_AND;

    -- Adder Unit
    g_NBit_ALUAdder: addsub_N
        port MAP(
            i_A        => i_A,
            i_B        => i_B,
            i_nAdd_Sub => '0',
            o_S        => s_addF,
            o_Co       => s_addCo
        );

    -- Subtractor Unit
    g_NBitALUSubtractor: addsub_N
        port MAP(
            i_A        => i_A,
            i_B        => i_B,
            i_nAdd_Sub => '1',
            o_S        => s_subF,
            o_Co       => s_subCo
        );

    -- Unsigned = logic; signed = arithmetic
    
    -- Left Shift Unit
    s_sllF <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned(i_B))));
    -- s_sla <= shift_left(signed(i_A), i_B);

    -- Right Shift Unit
    s_srlF <= std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned(i_B))));
    s_sraF <= std_logic_vector(shift_right(  signed(i_A), to_integer(unsigned(i_B))));

    -- Set-less-than Units
    s_sltuF <= 32x"1" when (unsigned(i_A) < unsigned(i_B)) else
               32x"0";
    s_sltF  <= 32x"1" when (signed(i_A) < signed(i_B)) else
               32x"0";

    o_F <= s_addF  when (i_ALUOp = work.RISCV_types.ADD)  else
           s_subF  when (i_ALUOp = work.RISCV_types.SUB)  else
           s_andF  when (i_ALUOp = work.RISCV_types.BAND) else
           s_orF   when (i_ALUOp = work.RISCV_types.BOR)  else
           s_xorF  when (i_ALUOp = work.RISCV_types.BXOR) else
           s_sllF  when (i_ALUOp = work.RISCV_types.BSLL) else
           s_srlF  when (i_ALUOp = work.RISCV_types.BSRL) else
           s_sraF  when (i_ALUOp = work.RISCV_types.BSRA) else
           s_sltF  when (i_ALUOp = work.RISCV_types.SLT)  else
           s_sltuF when (i_ALUOp = work.RISCV_types.SLTU) else
           32x"0";

    o_Co <= s_addCo when (i_ALUOp = work.RISCV_types.ADD) else
            s_subCo when (i_ALUOp = work.RISCV_types.SUB) else
            '0';

end mixed;
