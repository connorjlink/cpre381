library IEEE;
use IEEE.std_logic_1164.all;

package my_types is
    -- does this need vhdl 2008+?
    type array_t is array (natural range <>) of std_logic_vector(31 downto 0);
end my_types;