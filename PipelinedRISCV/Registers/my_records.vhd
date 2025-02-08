library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package my_records is

type controls_t is record

    -- instruction register contents
    IPAddr     : std_logic_vector(31 downto 0);
    Insn       : std_logic_vector(31 downto 0);
    -- end

    -- driver register contents
    MemWrite   : std_logic;
    RegWrite   : std_logic;
    RFSrc      : natural;
    ALUSrc     : std_logic;
    ALUOp      : natural;
    BGUOp      : natural;
    LSWidth    : natural;
    RD         : std_logic_vector(4 downto 0);
    RS1        : std_logic_vector(4 downto 0);
    RS2        : std_logic_vector(4 downto 0);
    DS1        : std_logic_vector(31 downto 0);
    DS2        : std_logic_vector(31 downto 0);
    Imm        : std_logic_vector(31 downto 0);
    BranchMode : natural;
    nInc2_Inc4 : std_logic;
    IPToALU    : std_logic;
    -- end

    -- alu register contents
    F          : std_logic_vector(31 downto 0);
    Co         : std_logic;
    -- end

    -- memory register contents
    Data       : std_logic_vector(31 downto 0);
    -- end

end record control_signals_t;

end package my_records;