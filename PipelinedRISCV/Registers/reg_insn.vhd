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
use work.my_records.all;

entity reg_insn is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_STALL    : in  std_logic;

        i_IPAddr   : in  std_logic_vector(31 downto 0);
        o_IPAddr   : out std_logic_vector(31 downto 0);

        i_LinkAddr : in  std_logic_vector(31 downto 0);
        o_LinkAddr : out std_logic_vector(31 downto 0);

        i_Insn     : in  std_logic_vector(31 downto 0);
        o_Insn     : out std_logic_vector(31 downto 0)
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
                    o_IPAddr   <= i_IPAddr;
                    o_LinkAddr <= i_LinkAddr;
                    o_Insn     <= i_Insn;
                end if;
            end if;
        else
            o_IPAddr   <= (others => '0');
            o_LinkAddr <= (others => '0');
            o_Insn     <= 32x"00000013"; -- insert NOPs to avoid an illegal instruction break
        end if;
    end process;

end behavioral;
