-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- mux32t1.vhd
-- DESCRIPTION: This file contains an implementation of a simple 32:1 multiplexer.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISCV_types.all;

entity mux32t1 is
    port(i_S : in  std_logic_vector(4 downto 0);
         i_D : in  work.RISCV_types.array_t(0 to 31);
         o_Q : out std_logic_vector(31 downto 0));
end mux32t1;

architecture dataflow of mux32t1 is
begin

    -- OLD model; would require specifying all 32 cases manually
    --o_Q <= i_D(0) when i_S = "00000" else
    
    o_Q <= i_D(to_integer(unsigned(i_S)));

end dataflow;
