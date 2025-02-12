-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- reg_insn.vhd
-- DESCRIPTION: This file contains an implementation of a RISC-V pipeline stage register.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_types.all;

entity reg_insn is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_STALL    : in  std_logic;

        i_Signals  : in  work.RISCV_types.insn_record_t;
        o_Signals  : out work.RISCV_types.insn_record_t
    );
end reg_insn;

architecture behavioral of reg_insn is

begin

    process(i_CLK, i_RST)
    begin
        if i_RST = '0' then
            -- for hardware scheduled pipeline, this will hook up to the hazard detection logic
            if i_STALL = '0' then
                if rising_edge(i_CLK) then
                    -- instruction register contents
                    o_Signals.IPAddr   <= i_Signals.IPAddr;
                    o_Signals.LinkAddr <= i_Signals.LinkAddr;
                    o_Signals.Insn     <= i_Signals.Insn;
                end if;
            end if;
        else
            o_Signals.IPAddr   <= (others => '0');
            o_Signals.LinkAddr <= (others => '0');
            o_Signals.Insn     <= 32x"00000013"; -- insert NOPs to avoid an illegal instruction break
        end if;
    end process;

end behavioral;
