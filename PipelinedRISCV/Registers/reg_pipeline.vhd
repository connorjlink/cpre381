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

entity reg_pipeline is
    generic(
        STAGE        : natural
    );
    port(
        i_CLK        : in  std_logic;
        i_RST        : in  std_logic;
        i_STALL      : in  std_logic;

        i_Signals    : in  work.my_records.controls_t;
        o_Signals    : out work.my_records.controls_t
    );
end reg_pipeline;

architecture behavioral of reg_pipeline is

 -- instruction register contents
 --o_Signals.o_IPAddr     <= i_Signals.i_IPAddr;
 --o_Signals.o_Insn       <= i_Signals.i_Insn;
 -- end

 -- driver register contents
 --o_Signals.o_MemWrite   <= i_Signals.i_MemWrite;
 --o_Signals.o_RegWRite   <= i_Signals.i_RegWrite;
 --o_Signals.o_RFSrc      <= i_Signals.i_RFSrc;
 --o_Signals.o_ALUSrc     <= i_Signals.i_ALUSrc;
 --o_Signals.o_ALUOp      <= i_Signals.i_ALUOp;
 --o_Signals.o_BGUOp      <= i_Signals.i_BGUOp;
 --o_Signals.o_LSWidth    <= i_Signals.i_LSWidth;
 --o_Signals.o_RD         <= i_Signals.i_RD;
 --o_Signals.o_RS1        <= i_Signals.i_RS1;
 --o_Signals.o_RS2        <= i_Signals.i_RS2;
 --o_Signals.o_DS1        <= i_Signals.i_DS1;
 --o_Signals.o_DS2        <= i_Signals.i_DS2;
 --o_Signals.o_Imm        <= i_Signals.i_Imm;
 --o_Signals.o_BranchMode <= i_Signals.i_BranchMode;
 --o_Signals.o_nInc2_Inc4 <= i_Signals.i_nInc2_Inc4;
 --o_Signals.o_ipToALU    <= i_Signals.i_ipToALU;
 -- end

 -- alu register contents
 --o_Signals.o_F          <= i_Signals.i_F;
 --o_Signals.o_Co         <= i_Signals.i_Co;
 -- end

 -- memory register contents
 --o_Signals.o_Data       <= i_Signals.i_Data;
 -- end

begin

    process(i_CLK, i_RST)
    begin
        if i_RST = '0' then
            -- for hardware scheduled pipeline, this will hook up to the hazard detection logic
            if i_STALL = '0' then
                if rising_edge(i_CLK) then
                    case STAGE is
                        when work.my_records.INSN =>
                            -- instruction register contents
                            o_Signals.IPAddr   <= i_Signals.IPAddr;
                            o_Signals.LinkAddr <= i_Signals.LinkAddr;
                            o_Signals.Insn     <= i_Signals.Insn;

                        when work.my_records.DRIVER =>
                            -- instruction register contents
                            o_Signals.IPAddr   <= i_Signals.IPAddr;
                            o_Signals.LinkAddr <= i_Signals.LinkAddr;
                            o_Signals.Insn     <= i_Signals.Insn;

                            -- driver register contents
                            o_Signals.Branch     <= i_Signals.Branch;    
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
                            o_Signals.nInc2_Inc4 <= i_Signals.nInc2_Inc4;
                            o_Signals.IPToALU    <= i_Signals.IPToALU;   

                        when work.my_records.ALU =>
                            -- ALU register contents
                            o_Signals.F  <= i_Signals.F;
                            o_Signals.Co <= i_Signals.Co;

                            -- instruction register contents
                            o_Signals.IPAddr   <= i_Signals.IPAddr;
                            o_Signals.LinkAddr <= i_Signals.LinkAddr;
                            o_Signals.Insn     <= i_Signals.Insn;

                            -- driver register contents
                            o_Signals.Branch     <= i_Signals.Branch;    
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
                            o_Signals.nInc2_Inc4 <= i_Signals.nInc2_Inc4;
                            o_Signals.IPToALU    <= i_Signals.IPToALU; 

                        when work.my_records.MEM =>
                            -- memory register contents
                            o_Signals.Data <= i_Signals.Data;

                            -- ALU register contents
                            o_Signals.F  <= i_Signals.F;
                            o_Signals.Co <= i_Signals.Co;

                            -- instruction register contents
                            o_Signals.IPAddr   <= i_Signals.IPAddr;
                            o_Signals.LinkAddr <= i_Signals.LinkAddr;
                            o_Signals.Insn     <= i_Signals.Insn;

                            -- driver register contents
                            o_Signals.Branch     <= i_Signals.Branch;    
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
                            o_Signals.nInc2_Inc4 <= i_Signals.nInc2_Inc4;
                            o_Signals.IPToALU    <= i_Signals.IPToALU; 

                        when others =>
                            o_Signals <= i_Signals;
                    end case;
                end if;
            end if;
        else
            -- TODO: reset all control signals here
            -- use others => '0' here!
        end if;
    end process;

end behavioral;
