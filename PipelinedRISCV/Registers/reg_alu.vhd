-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- reg_alu.vhd
-- DESCRIPTION: This file contains an implementation of a RISC-V pipeline stage register.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_types.all;

entity reg_alu is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_Stall    : in  std_logic;
        i_Flush    : in  std_logic;

        i_Signals  : in  work.RISCV_types.alu_record_t;
        o_Signals  : out work.RISCV_types.alu_record_t
    );
end reg_alu;

architecture behavioral of reg_alu is

begin

    process(i_CLK, i_RST)
    begin
        if i_RST = '1' or i_Flush = '1' then
            -- insert a NOP
            o_Signals.F  <= (others => '0');
            o_Signals.Co <= '0';
        else
            -- for hardware scheduled pipeline, this will hook up to the hazard detection logic
            if i_Stall = '0' and rising_edge(i_CLK) then
                -- alu register contents
                o_Signals.F  <= i_Signals.F;
                o_Signals.Co <= i_Signals.Co;
            end if;
        end if;
    end process;

end behavioral;
