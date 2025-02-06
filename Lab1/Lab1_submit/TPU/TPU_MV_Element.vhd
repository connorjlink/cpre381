-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- TPU_MV_Element.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a processing
-- element for the systolic matrix-vector multiplication array inspired 
-- by Google's TPU.
--
--
-- NOTES:
-- 1/14/19 by H3::Design created.
-- 1/16/25 by CWS::Switched from integer to std_logic_vector and numeric_std.
-- 1/31/25 by Connor Link to fix the bugs for CPRE 3810 lab 1
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TPU_MV_Element is

  generic(WIDTH : integer := 8);

  port(iCLK               : in std_logic;
       iX 		            : in std_logic_vector(WIDTH-1 downto 0);
       iW 		            : in std_logic_vector(WIDTH-1 downto 0);
       iLdW 		          : in std_logic;
       iY                 : in std_logic_vector(WIDTH-1 downto 0);
       oY 		            : out std_logic_vector(4*WIDTH-1 downto 0);
       oX 		            : out std_logic_vector(WIDTH-1 downto 0));

end TPU_MV_Element;

architecture structure of TPU_MV_Element is
  
  -- Describe the component entities as defined in Adder.vhd, Reg.vhd,
  -- Multiplier.vhd, RegLd.vhd (not strictly necessary).
  component Adder
    generic(A_WIDTH : integer := 32;
            B_WIDTH : integer := 32;
            C_WIDTH : integer := 32);
    port(iCLK             : in std_logic;
         iA               : in std_logic_vector(A_WIDTH-1 downto 0);
         iB               : in std_logic_vector(B_WIDTH-1 downto 0);
         oC               : out std_logic_vector(C_WIDTH-1 downto 0));
  end component;

  component Multiplier
    generic(DATA_WIDTH : integer := 8);
    port(iCLK           : in std_logic;
         iA             : in std_logic_vector(DATA_WIDTH-1 downto 0);
         iB             : in std_logic_vector(DATA_WIDTH-1 downto 0);
         oC             : out std_logic_vector(2*DATA_WIDTH-1 downto 0));
  end component;

  component Reg
    generic(DATA_WIDTH : integer := 32);
    port(iCLK           : in std_logic;
         iD             : in std_logic_vector(DATA_WIDTH-1 downto 0);
         oQ             : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;

  component RegLd
    generic(DATA_WIDTH : integer := 32);
    port(iCLK           : in std_logic;
         iD             : in std_logic_vector(DATA_WIDTH-1 downto 0);
         iLd            : in std_logic;
         oQ             : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component;


  -- Signal to carry stored weight
  signal s_W         : std_logic_vector(WIDTH-1 downto 0);
  -- Signals to carry delayed X
  signal s_X1        : std_logic_vector(WIDTH-1 downto 0);
  -- Signal to carry delayed Y
  signal s_Y1        : std_logic_vector(WIDTH-1 downto 0);
  -- Signal to carry stored W*X
  signal s_WxX       : std_logic_vector(2*WIDTH-1 downto 0);

begin

  ---------------------------------------------------------------------------
  -- Level 0: Conditionally load new W
  ---------------------------------------------------------------------------
 
  g_Weight: RegLd
    generic MAP(DATA_WIDTH => WIDTH)
    port MAP(iCLK             => iCLK,
             iD               => iW,
             iLd              => iLdW,
             oQ               => s_W);


  ---------------------------------------------------------------------------
  -- Level 1: Delay X and Y, calculate W*X
  ---------------------------------------------------------------------------
  g_Delay1: Reg
    generic MAP(DATA_WIDTH => WIDTH)
    port MAP(iCLK             => iCLK,
             iD               => iX,
             oQ               => s_X1);
  
  g_Delay2: Reg
    generic MAP(DATA_WIDTH => WIDTH)
    port MAP(iCLK             => iCLK,
             iD               => iY,
             oQ               => s_Y1);

  g_Mult1: Multiplier
    generic MAP(DATA_WIDTH => WIDTH)
    port MAP(iCLK             => iCLK,
             iA               => iX,
             iB               => s_W,
             oC               => s_WxX);

    
  ---------------------------------------------------------------------------
  -- Level 2: Delay X, calculate Y += W*X
  ---------------------------------------------------------------------------
  g_Delay3: Reg
    generic MAP(DATA_WIDTH => WIDTH)
    port MAP(iCLK             => iCLK,
             iD               => s_X1,
             oQ               => oX);

  g_Add1: Adder
    generic MAP(A_WIDTH => 2*WIDTH,
                B_WIDTH => WIDTH,
                C_WIDTH => 4*WIDTH)
    port MAP(iCLK             => iCLK,
             iA               => s_WxX,
             iB               => s_Y1,
             oC               => oY);
    

  end structure;
