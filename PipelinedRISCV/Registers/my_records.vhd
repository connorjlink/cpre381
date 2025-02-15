library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package my_records is

-- Corresponding enumerators for each pipeline stage
constant INSN   : natural := 0;
constant DRIVER : natural := 1;
constant ALU    : natural := 2;
constant MEM    : natural := 3;

type controls_t is record

    -- instruction register contents
    IPAddr     : std_logic_vector(31 downto 0);
    LinkAddr   : std_logic_vector(31 downto 0);
    Insn       : std_logic_vector(31 downto 0);
    -- end

    -- driver register contents
    Branch     : std_logic;
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
    IPStride   : std_logic; -- 0 = 2bytes, 1 = 4bytes
    SignExtend : std_logic; -- 0 = zero-extend, 1 = sign-extend
    IPToALU    : std_logic;
    -- end

    -- alu register contents
    F          : std_logic_vector(31 downto 0);
    Co         : std_logic;
    -- end

    -- memory register contents
    Data       : std_logic_vector(31 downto 0);
    -- end

end record controls_t;

end package my_records;