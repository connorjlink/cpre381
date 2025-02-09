-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- reg_mem.vhd
-- DESCRIPTION: This file contains an implementation of a RISC-V pipeline stage register.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_records.all;

entity reg_mem is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_STALL    : in  std_logic;

        i_Data     : in  std_logic_vector(31 downto 0);
        o_Data     : out std_logic_vector(31 downto 0)
    );
end reg_mem;

architecture behavioral of reg_mem is

begin

    process(i_CLK, i_RST)
    begin
        if i_RST = '0' then
            -- for hardware scheduled pipeline, this will hook up to the hazard detection logic
            if i_STALL = '0' then
                if rising_edge(i_CLK) then
                    -- alu register contents
                    o_Data <= i_Data;
                end if;
            end if;
        else
            o_Data <= (others => '0');
        end if;
    end process;

end behavioral;
