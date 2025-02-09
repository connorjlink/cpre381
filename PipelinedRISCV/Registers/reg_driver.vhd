-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- reg_pipeline.vhd
-- DESCRIPTION: This file contains an implementation of a generic RISC-V pipeline stage register.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.my_records.all;

entity reg_driver is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_STALL    : in  std_logic;

        i_MemWrite   : in  std_logic;
        o_MemWrite   : out std_logic;

        i_RegWrite   : in  std_logic;
        o_RegWrite   : out std_logic;

        i_RFSrc      : in  natural;
        o_RFSrc      : out natural;

        i_ALUSrc     : in  std_logic;
        o_ALUSrc     : out std_logic;

        i_ALUOp      : in  natural;
        o_ALUOp      : out natural;

        i_BGUOp      : in  natural;
        o_BGUOp      : out natural;

        i_LSWidth    : in  natural;
        o_LSWidth    : out natural;

        i_RD         : in  std_logic_vector(4 downto 0);
        o_RD         : out std_logic_vector(4 downto 0);

        i_RS1        : in  std_logic_vector(4 downto 0);
        o_RS1        : out std_logic_vector(4 downto 0);

        i_RS2        : in  std_logic_vector(4 downto 0);
        o_RS2        : out std_logic_vector(4 downto 0);

        i_DS1        : in  std_logic_vector(31 downto 0);
        o_DS1        : out std_logic_vector(31 downto 0);

        i_DS2        : in  std_logic_vector(31 downto 0);
        o_DS2        : out std_logic_vector(31 downto 0);

        i_Imm        : in  std_logic_vector(31 downto 0);
        o_Imm        : out std_logic_vector(31 downto 0);

        i_BranchMode : in  natural;
        o_BranchMode : out natural;

        i_nInc2_Inc4 : in  std_logic;
        o_nInc2_Inc4 : out std_logic;
        
        i_IPToALU    : in  std_logic;
        o_IPToALU    : out std_logic
    );
end reg_driver;

architecture behavioral of reg_driver is

begin

    process(i_CLK, i_RST)
    begin
        if i_RST = '0' then
            -- for hardware scheduled pipeline, this will hook up to the hazard detection logic
            if i_STALL = '0' then
                if rising_edge(i_CLK) then
                    -- driver register contents
                    o_MemWrite   <= i_MemWrite;  
                    o_RegWrite   <= i_RegWrite;  
                    o_RFSrc      <= i_RFSrc;     
                    o_ALUSrc     <= i_ALUSrc;    
                    o_ALUOp      <= i_ALUOp;     
                    o_BGUOp      <= i_BGUOp;     
                    o_LSWidth    <= i_LSWidth;   
                    o_RD         <= i_RD;        
                    o_RS1        <= i_RS1;       
                    o_RS2        <= i_RS2;       
                    o_DS1        <= i_DS1;       
                    o_DS2        <= i_DS2;       
                    o_Imm        <= i_Imm;       
                    o_BranchMode <= i_BranchMode;
                    o_nInc2_Inc4 <= i_nInc2_Inc4;
                    o_IPToALU    <= i_IPToALU;   
                end if;
            end if;
        else
            o_MemWrite   <= '0';
            o_RegWrite   <= '0';
            o_RFSrc      <= 0;
            o_ALUSrc     <= '0';
            o_ALUOp      <= 0;
            o_BGUOp      <= 0;
            o_LSWidth    <= 0;
            o_RD         <= (others => '0');
            o_RS1        <= (others => '0');
            o_RS2        <= (others => '0');
            o_DS1        <= (others => '0');
            o_DS2        <= (others => '0');
            o_Imm        <= (others => '0');
            o_BranchMode <= 0;
            o_nInc2_Inc4 <= '0';
            o_IPToALU    <= '0';
        end if;
    end process;

end behavioral;
