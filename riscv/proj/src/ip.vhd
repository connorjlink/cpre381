-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- ip.vhd
-- DESCRIPTION: This file contains an implementation of a basic RISC-V instruction pointer assembly.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ip is
    generic(
        -- Signal to hold the default data page address (according to RARS at least)
        ResetAddress : std_logic_vector(31 downto 0) := 32x"00400000"
    );
    port(
        i_CLK        : in  std_logic;
        i_RST        : in  std_logic;
        i_Load       : in  std_logic;
        i_Addr       : in  std_logic_vector(31 downto 0);
        i_nInc2_Inc4 : in  std_logic; -- 0 = inc2, 1 = inc4
        i_Stall      : in  std_logic;
        o_Addr       : out std_logic_vector(31 downto 0);
        o_LinkAddr   : out std_logic_vector(31 downto 0)
    );
end ip;

architecture mixed of ip is

component register_N is
    generic(
        N : integer := 32
    );
    port(
        i_CLK : in  std_logic;                       -- Clock input
        i_RST : in  std_logic;                       -- Reset input
        i_WE  : in  std_logic;                       -- Write enable input
        i_D   : in  std_logic_vector(N-1 downto 0);  -- Data value input
        o_Q   : out std_logic_vector(N-1 downto 0)   -- Data value output
    ); 
end component;

component adder_N is
    generic(
        N : integer := 32
    );
    port(
        i_A  : in  std_logic_vector(N-1 downto 0);
        i_B  : in  std_logic_vector(N-1 downto 0);
        i_Ci : in  std_logic;
        o_S  : out std_logic_vector(N-1 downto 0);
        o_Co : out std_logic
    );
end component;

-- Signals to hold the intermediate values used to drive the instruction pointer register
signal s_IPWrite : std_logic;
signal s_IPData : std_logic_vector(31 downto 0);
signal s_IPAddr : std_logic_vector(31 downto 0);

-- Signals to hold the intermediate values used to drive the upcounter
signal s_IPStride : std_logic_vector(31 downto 0);
signal s_LinkAddr : std_logic_vector(31 downto 0);

begin

    s_IPData <= ResetAddress when i_RST = '1'  else
                i_Addr       when i_Load = '1' else
                s_LinkAddr;

    -- Upcounting is disabled when we need a pipeline stall
    s_IPWrite <= '1' when i_Load  = '1' else
                 '0' when i_Stall = '1' else
                 '1';

    g_InstructionPointer: register_N
        generic MAP(
            N => 32
        )
        port MAP(
            i_CLK => i_CLK,
            i_RST => '0', -- i_RST, -- FIXME: 
            i_WE  => s_IPWrite,
            i_D   => s_IPData,
            o_Q   => s_IPAddr
        );

    s_IPStride <= 32x"2" when i_nInc2_Inc4 = '0' else
                  32x"4";

    g_Upcounter: adder_N
        generic MAP(
            N => 32
        )
        port MAP(
            i_A   => s_IPAddr,
            i_B   => s_IPStride,
            i_Ci  => '0',
            o_S   => s_LinkAddr,
            o_Co => open
        );

    o_Addr     <= s_IPAddr;
    o_LinkAddr <= s_LinkAddr;
    
end mixed;
