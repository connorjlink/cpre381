-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- ext.vhd
-- DESCRIPTION: This file contains an implementation of a simple N:M-bit sign and zero extender for RISC-V.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ext is
    generic(IN_WIDTH  : integer := 12;
            OUT_WIDTH : integer := 32); 
    port(i_D          : in  std_logic_vector(IN_WIDTH-1 downto 0);
         i_nZero_Sign : in  std_logic;
         o_Q          : out std_logic_vector(OUT_WIDTH-1 downto 0));
end ext;

architecture dataflow of ext is

-- Signals to hold the intermediate zero- and sign-extended results
signal s_Rz : std_logic_vector(OUT_WIDTH-1 downto 0);
signal s_Rs : std_logic_vector(OUT_WIDTH-1 downto 0);

begin

    -- Use numeric_std conversions for extensions
    s_Rz <= std_logic_vector(resize(unsigned(i_D), OUT_WIDTH));
    s_Rs <= std_logic_vector(resize(signed(i_D), OUT_WIDTH));

    -- "Multiplex" the result
    o_Q  <= s_Rz when i_nZero_Sign = '0' else s_Rs;

end dataflow;
