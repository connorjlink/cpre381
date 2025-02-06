-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- mux2t1d.vhd
-- DESCRIPTION: This file contains an implementation of a simple 2:1 multiplexer
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity mux2t1d is
    port(i_D0 : in  std_logic;
         i_D1 : in  std_logic;
         i_S  : in  std_logic;
         o_O  : out std_logic);
end mux2t1d;

architecture dataflow of mux2t1d is
begin

    o_O <= (i_D0 and not i_S) or (i_D1 and i_S);

end dataflow;
