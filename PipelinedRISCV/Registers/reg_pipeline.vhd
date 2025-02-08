-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- reg_pipeline.vhd
-- DESCRIPTION: This file contains an implementation of a generic RISC-V pipeline stage register.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_records.all;

entity reg_pipeline is
    port(
        i_CLK        : in  std_logic;
        i_RST        : in  std_logic;
        i_STALL      : in  std_logic;

        i_Signals    : in  my_records.i_controls_t;
        o_Signals    : out my_records.o_controls_t;
    );
end reg_alu;

architecture behavioral of reg_alu is

begin

    process(i_CLK, i_RST)
    begin
        if i_RST = '0' then
            -- for hardware scheduled pipeline, this will hook up to the hazard detection logic
            if i_STALL = '0' then
                if rising_edge(i_CLK) then
                    -- instruction register contents
                    o_Signals.o_IPAddr     <= i_Signals.i_IPAddr;
                    o_Signals.o_Insn       <= i_Signals.i_Insn;
                    -- end

                    -- driver register contents
                    o_Signals.o_MemWrite   <= i_Signals.i_MemWrite;
                    o_Signals.o_RegWRite   <= i_Signals.i_RegWrite;
                    o_Signals.o_RFSrc      <= i_Signals.i_RFSrc;
                    o_Signals.o_ALUSrc     <= i_Signals.i_ALUSrc;
                    o_Signals.o_ALUOp      <= i_Signals.i_ALUOp;
                    o_Signals.o_BGUOp      <= i_Signals.i_BGUOp;
                    o_Signals.o_LSWidth    <= i_Signals.i_LSWidth;
                    o_Signals.o_RD         <= i_Signals.i_RD;
                    o_Signals.o_RS1        <= i_Signals.i_RS1;
                    o_Signals.o_RS2        <= i_Signals.i_RS2;
                    o_Signals.o_DS1        <= i_Signals.i_DS1;
                    o_Signals.o_DS2        <= i_Signals.i_DS2;
                    o_Signals.o_Imm        <= i_Signals.i_Imm;
                    o_Signals.o_BranchMode <= i_Signals.i_BranchMode;
                    o_Signals.o_nInc2_Inc4 <= i_Signals.i_nInc2_Inc4;
                    o_Signals.o_ipToALU    <= i_Signals.i_ipToALU;
                    -- end

                    -- alu register contents
                    o_Signals.o_F          <= i_Signals.i_F;
                    o_Signals.o_Co         <= i_Signals.i_Co;
                    -- end

                    -- memory register contents
                    o_Signals.o_Data       <= i_Signals.i_Data;
                    -- end
                end if;
            end if;
        else
            -- TODO: reset all control signals here
            -- use others => '0' here!
        end if;
    end process;

end behavioral;
