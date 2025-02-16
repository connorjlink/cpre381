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
use work.RISCV_types.all;

entity reg_driver is
    port(
        i_CLK      : in  std_logic;
        i_RST      : in  std_logic;
        i_Stall    : in  std_logic;
        i_Flush    : in  std_logic;

        i_Signals  : in  work.RISCV_types.driver_record_t;
        o_Signals  : out work.RISCV_types.driver_record_t
    );
end reg_driver;

architecture behavioral of reg_driver is

begin

    process(i_CLK, i_RST)
    begin
        if i_RST = '1' or i_Flush = '1' then
            -- insert a NOP
            o_Signals.MemWrite   <= '0';
            o_Signals.RegWrite   <= '0';
            o_Signals.RFSrc      <= 0;
            o_Signals.ALUSrc     <= '0';
            o_Signals.ALUOp      <= 0;
            o_Signals.BGUOp      <= 0;
            o_Signals.LSWidth    <= 0;
            o_Signals.RD         <= (others => '0');
            o_Signals.RS1        <= (others => '0');
            o_Signals.RS2        <= (others => '0');
            o_Signals.DS1        <= (others => '0');
            o_Signals.DS2        <= (others => '0');
            o_Signals.Imm        <= (others => '0');
            o_Signals.BranchMode <= 0;
            o_Signals.Break      <= '0';
            o_Signals.IsBranch   <= '0';
            o_Signals.IPStride   <= '0';
            o_Signals.SignExtend <= '0';
            o_Signals.IPToALU    <= '0';
        else
            -- for hardware scheduled pipeline, this will hook up to the hazard detection logic
            if i_STALL = '0' and rising_edge(i_CLK) then
                -- driver register contents
                o_Signals.MemWrite   <= i_Signals.MemWrite;  
                o_Signals.RegWrite   <= i_Signals.RegWrite;  
                o_Signals.RFSrc      <= i_Signals.RFSrc;     
                o_Signals.ALUSrc     <= i_Signals.ALUSrc;    
                o_Signals.ALUOp      <= i_Signals.ALUOp;     
                o_Signals.BGUOp      <= i_Signals.BGUOp;     
                o_Signals.LSWidth    <= i_Signals.LSWidth;   
                o_Signals.RD         <= i_Signals.RD;        
                o_Signals.RS1        <= i_Signals.RS1;       
                o_Signals.RS2        <= i_Signals.RS2;       
                o_Signals.DS1        <= i_Signals.DS1;       
                o_Signals.DS2        <= i_Signals.DS2;       
                o_Signals.Imm        <= i_Signals.Imm;       
                o_Signals.BranchMode <= i_Signals.BranchMode;
                o_Signals.Break      <= i_Signals.Break;
                o_Signals.IsBranch   <= i_Signals.IsBranch;
                o_Signals.IPStride   <= i_Signals.IPStride;
                o_Signals.SignExtend <= i_Signals.SignExtend;
                o_Signals.IPToALU    <= i_Signals.IPToALU;   
            end if;
        end if;
    end process;

end behavioral;
