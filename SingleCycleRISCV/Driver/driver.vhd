-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- driver.vhd
-- DESCRIPTION: This file contains an implementation of a basic RISC-V control logic driver circuit.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.my_enums.all;

entity driver is
    port(
        i_CLK        : in  std_logic;
        i_RST        : in  std_logic;
        i_Insn       : in  std_logic_vector(31 downto 0);
        i_Branch     : in  std_logic;
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
        o_nInc2_Inc4 : out std_logic;
        o_ipToALU    : out std_logic
    );
end driver;

architecture mixed of driver is

component ext is
    generic(
        IN_WIDTH  : integer := 12;
        OUT_WIDTH : integer := 32
    ); 
    port(
        i_D          : in  std_logic_vector(IN_WIDTH-1 downto 0);
        i_nZero_Sign : in  std_logic;
        o_Q          : out std_logic_vector(OUT_WIDTH-1 downto 0)
    );
end component;

component decoder is
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
end component;

-- Signals to hold the results from the decoder
signal s_decOpcode : std_logic_vector(6 downto 0);
signal s_decFunc3  : std_logic_vector(2 downto 0);
signal s_decFunc7  : std_logic_vector(6 downto 0);
signal s_deciImm   : std_logic_vector(11 downto 0);
signal s_decsImm   : std_logic_vector(11 downto 0);
signal s_decbImm   : std_logic_vector(12 downto 0);
signal s_decuImm   : std_logic_vector(31 downto 12);
signal s_decjImm   : std_logic_vector(20 downto 0);
signal s_dechImm   : std_logic_vector(4 downto 0);

-- Signals to hold the results from the immediate extenders
signal s_extiImm : std_logic_vector(31 downto 0);
signal s_extsImm : std_logic_vector(31 downto 0);
signal s_extbImm : std_logic_vector(31 downto 0);
signal s_extuImm : std_logic_vector(31 downto 0);
signal s_extjImm : std_logic_vector(31 downto 0);
signal s_exthImm : std_logic_vector(31 downto 0);

-- Signal to hold the immediate extension information
signal s_nZeroSign : std_logic;


begin

    -- 4-byte instructions are indicated by a 11 in the two least-significant bits of the opcode
    o_nInc2_Inc4 <= '1' when s_decOpcode(1 downto 0) = 2b"11" else
                    '0';

    g_DriverExtenderI: ext -- I-Format
        generic MAP(
            IN_WIDTH => 12,
            OUT_WIDTH => 32
        )
        port MAP(
            i_D          => s_deciImm,
            i_nZero_Sign => s_nZeroSign,
            o_Q          => s_extiImm
        );

    g_DriverExtenderS: ext -- S-Format
        generic MAP(
            IN_WIDTH => 12,
            OUT_WIDTH => 32
        )
        port MAP(
            i_D          => s_decsImm,
            i_nZero_Sign => s_nZeroSign,
            o_Q          => s_extsImm
        );

    g_DriverExtenderB: ext -- B-Format
        generic MAP(
            IN_WIDTH => 13,
            OUT_WIDTH => 32
        )
        port MAP(
            i_D          => s_decbImm,
            i_nZero_Sign => s_nZeroSign,
            o_Q          => s_extbImm
        );

    -- U-Format
    s_extuImm(31 downto 12) <= s_decuImm;
    s_extuImm(11 downto 0) <= 12x"0";

    g_DriverExtenderJ: ext -- J-Format
        generic MAP(
            IN_WIDTH => 21,
            OUT_WIDTH => 32
        )
        port MAP(
            i_D          => s_decjImm,
            i_nZero_Sign => s_nZeroSign,
            o_Q          => s_extjImm
        );

    -- "H"-format for shift immediate
    s_exthImm(31 downto 5) <= 27x"0";
    s_exthImm(4 downto 0) <= s_dechImm;


    g_InstructionDecoder: decoder
        port MAP(
            i_CLK    => i_CLK,
            i_RST    => i_RST,
            i_Insn   => i_Insn,
            o_Opcode => s_decOpcode,
            o_RD     => o_RD,
            o_RS1    => o_RS1,
            o_RS2    => o_RS2,
            o_Func3  => s_decFunc3,
            o_Func7  => s_decFunc7,
            o_iImm   => s_deciImm,
            o_sImm   => s_decsImm,
            o_bImm   => s_decbImm,
            o_uImm   => s_decuImm,
            o_jImm   => s_decjImm,
            o_hImm   => s_dechImm
        );

    process(i_RST, i_Insn, s_decOpcode, s_decFunc3, s_decFunc7, 
            s_extiImm, s_extsImm, s_extbImm, s_extuImm, s_extjImm)
        variable v_Break      : std_logic;
        variable v_nZeroSign  : std_logic;
        variable v_MemWrite   : std_logic;
        variable v_RegWrite   : std_logic;
        variable v_ALUSrc     : std_logic;
        variable v_RFSrc      : natural; -- 0 = memory, 1 = ALU, 2 = next IP
        variable v_ALUOp      : natural;
        variable v_BGUOp      : natural;
        variable v_LSWidth    : natural;
        variable v_Imm        : std_logic_vector(31 downto 0);
        variable v_BranchMode : natural;
        variable v_ipToALU    : std_logic;
    begin 
        if i_RST = '0' then
            v_Break      := '0';
            v_nZeroSign  := '1'; -- default case is sign extension
            v_MemWrite   := '0';
            v_RegWrite   := '0';
            v_RFSrc      := 0;
            v_ALUSrc     := '0';
            v_ALUOp      := 0;
            v_BGUOp      := 0;
            v_Imm        := 32x"0";
            v_BranchMode := 0;
            v_ipToALU    := '0';

            case s_decOpcode is 
                -- TODO: linking jump
                when 7b"1101111" => -- J-Format
                    -- jal    - rd <= linkAddr
                    v_Imm := s_extjImm;
                    v_BGUOp := work.my_enums.J;
                    v_RegWrite := '1';
                    v_RFSrc := work.my_enums.FROM_NEXTIP;
                    v_BranchMode := work.my_enums.JAL;
                    report "jal" severity note;

                when 7b"1100111" => -- I-Format
                    -- jalr - func3=000 - rd <= linkAddr
                    v_Imm := s_extiImm;
                    v_BGUOp := work.my_enums.J;
                    v_RegWrite := '1';
                    v_RFSrc := work.my_enums.FROM_NEXTIP;
                    v_BranchMode := work.my_enums.JALR;
                    report "jalr" severity note;

                when 7b"0010011" => -- I-format
                    v_RegWrite := '1';
                    v_ALUSrc := '1';
                    v_RFSrc := work.my_enums.FROM_ALU;
                    v_Imm := s_extiImm;

                    case s_decFunc3 is
                        when 3b"000" =>
                            if s_decFunc7 = 7b"0100000" then
                                -- subi  - 000 + 0100000
                                v_ALUOp := work.my_enums.SUB;
                                report "subi" severity note;

                            else
                                -- addi  - 000 + 0000000
                                v_ALUOp := work.my_enums.ADD;
                                report "addi" severity note;

                            end if;

                        when 3b"001" =>
                            -- slli  - 001
                            v_ALUOp := work.my_enums.BSLL;
                            v_Imm := s_exthImm; -- override for shamt
                            report "slli" severity note;

                        when 3b"010" => 
                            -- slti  - 010
                            v_ALUOp := work.my_enums.SLT;
                            report "slti" severity note;

                        when 3b"011" =>
                            -- sltiu - 011
                            v_ALUOp := work.my_enums.SLTU;
                            report "sltiu" severity note;

                        when 3b"100" =>
                            -- xori  - 100
                            v_ALUOp := work.my_enums.BXOR;
                            report "xori" severity note;

                        when 3b"101" =>
                            -- shtype field is equivalent to func7
                            if s_decFunc7 = 7b"0100000" then
                                -- srai - 101 + 0100000
                                v_ALUOp := work.my_enums.BSRA;
                                v_Imm := s_exthImm; -- override for shamt
                                report "srai" severity note;

                            else
                                -- srli - 101 + 0000000
                                v_ALUOp := work.my_enums.BSRL;
                                v_Imm := s_exthImm; -- override for shamt
                                report "srli" severity note;
                            
                            end if;

                        when 3b"110" =>
                            -- ori  - 110
                            v_ALUOp := work.my_enums.BOR;
                            report "ori" severity note;

                        when 3b"111" =>
                            -- andi - 111
                            v_ALUOp := work.my_enums.BAND;
                            report "andi" severity note;

                        when others =>
                            v_Break := '1';
                            report "Illegal I-Format Instruction" severity error;
                    end case;

                when 7b"0000011" => -- I-Format? More
                    v_RegWrite := '1';
                    v_RFSrc := work.my_enums.FROM_RAM;
                    v_ALUSrc := '1'; --?
                    v_Imm := s_extiImm;

                    case s_decFunc3 is
                        when 3b"000" =>
                            -- lb   - 000
                            v_LSWidth := work.my_enums.BYTE;
                            report "lb" severity note;

                        when 3b"001" =>
                            -- lh   - 001
                            v_LSWidth := work.my_enums.HALF;
                            report "lh" severity note;

                        when 3b"010" =>
                            -- lw   - 010
                            v_LSWidth := work.my_enums.WORD;
                            report "lw" severity note;

                        when 3b"011" =>
                            -- ld   - 011
                            v_LSWidth := work.my_enums.DOUBLE;
                            report "ld" severity note;

                        when 3b"100" =>
                            -- lbu  - 100
                            v_nZeroSign := '0';
                            v_LSWidth := work.my_enums.BYTE;
                            report "lbu" severity note;

                        when 3b"101" =>
                            -- lhu  - 101
                            v_nZeroSign := '0';
                            v_LSWidth := work.my_enums.HALF;
                            report "lhu" severity note;

                        -- NOTE: unoffical (since not necessary), but not illegal
                        when 3b"110" =>
                            -- lwu  - 110
                            v_nZeroSign := '0';
                            v_LSWidth := work.my_enums.WORD;
                            report "lwu" severity note;

                        -- NOTE: unoffical (since not necessary), but not illegal
                        when 3b"111" =>
                            -- ldu  - 111
                            v_nZeroSign := '0';
                            v_LSWidth := work.my_enums.DOUBLE;
                            report "ldu" severity note;

                        when others =>
                            v_Break := '1';
                            report "Illegal I-Format? More Instruction" severity error;
                    end case;

                when 7b"0100011" => -- S-Format
                    v_MemWrite := '1';
                    v_ALUSrc := '1'; --?
                    v_Imm := s_extsImm;

                    case s_decFunc3 is
                        when 3b"000" =>
                            -- sb   - 000
                            v_LSWidth := work.my_enums.BYTE;
                            report "sb" severity note;

                        when 3b"001" =>
                            -- sh   - 001
                            v_LSWidth := work.my_enums.HALF;
                            report "sh" severity note;

                        when 3b"010" =>
                            -- sw   - 010
                            v_LSWidth := work.my_enums.WORD;
                            report "sw" severity note;

                        when 3b"011" =>
                            -- sd   - 011
                            v_LSWidth := work.my_enums.DOUBLE;
                            report "sd" severity note;

                        when others =>
                            v_Break := '1';
                            report "Illegal S-Format Instruction" severity error;
                    end case;

                when 7b"0110011" => -- R-format
                    v_RegWrite := '1';
                    v_RFSrc := work.my_enums.FROM_ALU;
                    v_ALUSrc := '0';

                    case s_decFunc3 is
                        when 3b"000" =>
                            if s_decFunc7 = 7b"0100000" then
                                -- sub  - 000 + 0100000
                                v_ALUOp := work.my_enums.SUB;
                                report "sub" severity note;

                            else
                                -- add  - 000 + 0000000
                                v_ALUOp := work.my_enums.ADD;
                                report "add" severity note;

                            end if;

                        when 3b"001" =>
                            -- sll  - 001 + 0000000
                            v_ALUOp := work.my_enums.BSLL;
                            report "sll" severity note;

                        when 3b"010" =>
                            -- slt  - 010 + 0000000
                            v_ALUOp := work.my_enums.SLT;
                            report "slt" severity note;

                        when 3b"011" =>
                            -- sltu - 011 + 0000000
                            v_ALUOp := work.my_enums.SLTU;
                            report "sltu" severity note;

                        when 3b"100" =>
                            -- xor  - 100 + 0000000
                            v_ALUOp := work.my_enums.BXOR;
                            report "xor" severity note;

                        when 3b"101" =>
                            -- shtype field is equivalent to func7
                            if s_decFunc7 = 7b"0100000" then
                                -- sra - 101 + 0100000
                                v_ALUOp := work.my_enums.BSRA;
                                report "sra" severity note;

                            else
                                -- srl - 101 + 0000000
                                v_ALUOp := work.my_enums.BSRL;
                                report "srl" severity note;

                            end if;

                        when 3b"110" =>
                            -- or   - 110 + 0000000
                            v_ALUOp := work.my_enums.BOR;
                            report "or" severity note;

                        when 3b"111" =>
                            -- and  - 111 + 0000000
                            v_ALUOp := work.my_enums.BAND;
                            report "and" severity note;

                        when others =>
                            v_Break := '1';
                            report "Illegal R-Format Instruction" severity error;
                    end case;

                when 7b"1100011" => -- B-Format
                    v_Imm := s_extbImm;
                    -- v_ALUSrc := '1';
                    -- v_ipToALU := '1';
                    v_BranchMode := work.my_enums.BCC;

                    case s_decFunc3 is 
                        when 3b"000" =>
                            -- beq  - 000
                            v_BGUOp := work.my_enums.BEQ;
                            report "beq" severity note;

                        when 3b"001" =>
                            -- bne  - 001
                            v_BGUOp := work.my_enums.BNE;
                            report "bne" severity note;

                        when 3b"100" =>
                            -- blt  - 100
                            v_BGUOp := work.my_enums.BLT;
                            report "blt" severity note;

                        when 3b"101" =>
                            -- bge  - 101
                            v_BGUOp := work.my_enums.BGE;
                            report "bge" severity note;

                        when 3b"110" =>
                            -- bltu - 110
                            v_BGUOp := work.my_enums.BLTU;
                            report "bltu" severity note;

                        when 3b"111" =>
                            -- bgeu - 111
                            v_BGUOp := work.my_enums.BGEU;
                            report "bgeu" severity note;

                        when others =>
                            v_Break := '1';
                            report "Illegal B-Format Instruction" severity error;
                    end case;

                when 7b"0110111" => -- U-Format
                    -- lui   - rd = imm << 12
                    v_Imm := s_extuImm;
                    v_RFSrc := work.my_enums.FROM_IMM;
                    v_RegWrite := '1';
                    report "lui" severity note;

                when 7b"0010111" => -- U-Format
                    -- auipc - rd = pc + (imm << 12)
                    v_Imm := s_extuImm;
                    v_RFSrc := work.my_enums.FROM_ALU;
                    v_ALUSrc := '1';
                    v_ipToALU := '1';
                    v_RegWrite := '1';
                    report "auipc" severity note;

                -- NOTE: `0001111` - "fence" not required by RV32I
                -- NOTE: `1110011` - "ecall/ebreak" not required by RV32I

                when others =>
                    v_Break := '1';
                    report "Illegal Instruction" severity error;
            end case;
        else
            v_Break      := '0';
            v_nZeroSign  := '1'; -- default case is sign extension
            v_MemWrite   := '0';
            v_RegWrite   := '0';
            v_RFSrc      := 0;
            v_ALUSrc     := '0';
            v_ALUOp      := 0;
            v_BGUOp      := 0;
            v_Imm        := 32x"0";
            v_BranchMode := 0;
            v_ipToALU    := '0';
        end if;

        o_Break      <= v_Break;
        s_nZeroSign  <= v_nZeroSign;
        o_MemWrite   <= v_MemWrite; 
        o_RegWrite   <= v_RegWrite; 
        o_RFSrc      <= v_RFSrc;    
        o_ALUSrc     <= v_ALUSrc;   
        o_ALUOp      <= v_ALUOp;    
        o_BGUOp      <= v_BGUOp; 
        o_LSWidth    <= v_LSWidth;   
        o_Imm        <= v_Imm;  
        o_BranchMode <= v_BranchMode;   
        o_ipToALU    <= v_ipToALU; 
    end process;

end mixed;
