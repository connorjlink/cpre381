------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- dfu.vhd
-- DESCRIPTION: This file contains an implementation of a basic RISC-V data forwarder.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.RISCV_types.all;

entity dfu is
    port(
        i_InsnRS1      : in  std_logic_vector(4 downto 0);
        i_InsnRS2      : in  std_logic_vector(4 downto 0);
        
        i_DriverRS1    : in  std_logic_vector(4 downto 0);
        i_DriverRS2    : in  std_logic_vector(4 downto 0);
        
        i_ALURS1       : in  std_logic_vector(4 downto 0);
        i_ALURS2       : in  std_logic_vector(4 downto 0);
        i_ALURegWrite  : in  std_logic;
        
        i_MemRD        : in  std_logic_vector(4 downto 0);
        i_MemRS1       : in  std_logic_vector(4 downto 0);
        i_MemRS2       : in  std_logic_vector(4 downto 0);
        i_MemRegWrite  : in  std_logic;

        i_BranchMode   : in  natural;
        i_Branch       : in  std_logic; -- indicate if the branch is taken or not (hooks to output of BGU)
        i_IsBranch     : in  std_logic;

        o_ForwardALUToALUOperand1 : out std_logic;
        o_ForwardALUToALUOperand2 : out std_logic;
        
        o_ForwardMemToALUOperand1 : out std_logic;
        o_ForwardMemToALUOperand2 : out std_logic;
        
        o_ForwardMemToDriverRS1   : out std_logic;
        o_ForwardMemToDriverRS2   : out std_logic;
        
        o_ForwardALUToDriverRS1   : out std_logic;
        o_ForwardALUToDriverRS2   : out std_logic
    );
end dfu;

architecture mixed of dfu is

begin

    process(
        i_InsnRS1, i_InsnRS2,
        i_DriverRS1, i_DriverRS2,
        i_ALURS1, i_ALURS2, i_ALURegWrite,
        i_MemRD, i_MemRS1, i_MemRS2, i_MemRegWrite,
        i_BranchMode, i_Branch, i_IsBranch
    )
        variable v_ForwardALUToALUOperand1 : std_logic := '0';
        variable v_ForwardALUToALUOperand2 : std_logic := '0';

        variable v_ForwardMemToALUOperand1 : std_logic := '0';
        variable v_ForwardMemToALUOperand2 : std_logic := '0';

        variable v_ForwardMemToDriverRS1 : std_logic := '0';
        variable v_ForwardMemToDriverRS2 : std_logic := '0';

        variable v_ForwardALUToDriverRS1 : std_logic := '0';
        variable v_ForwardALUToDriverRS2 : std_logic := '0';

    begin
        -- Hazard Conditions Handled Here:
        --   a.) Read-after-write:
        --     i. Forward ALU register to ALU operands (1 and 2)
        --     ii. Forward Mem register to ALU operands
        --     iii. Forward ALU register to driver register read (DSn) values
        --     iv. Forward Mem register to driver register read (DSn) values

        -- Hazard Conditions Not Handled Here:
        --   b.) Load-use?: FIXME: requires stalling?
        --   c.) Branching (at least not properly right now)

        -- Case a.i:
        if i_ALURegWrite = '1' and i_ALURS1 = i_DriverRS1 and i_ALURS1 /= 5x"0" then
            v_ForwardALUToALUOperand1 := '1';
        elsif i_ALURegWrite = '1' and i_ALURS2 = i_DriverRS2 and i_ALURS2 /= 5x"0" then
            v_ForwardALUToALUOperand2 := '1';
        end if;

        -- Case a.ii:
        if i_MemRegWrite = '1' and i_MemRS1 = i_DriverRS1 and i_MemRS1 /= 5x"0" then
            v_ForwardMemToALUOperand1 := '1';
        elsif i_MemRegWrite = '1' and i_MemRS2 = i_DriverRS2 and i_MemRS2 /= 5x"0" then
            v_ForwardMemToALUoperand2 := '1';
        end if;
            
        -- Case a.iii:
        if i_MemRD = i_InsnRS1 and i_MemRD /= 5x"0" then
            -- TODO: i_InsnRS1 might need to be the raw fetch output and not the register buffered value
            -- FIXME: if i_Branch = '1' or i_JumpAndLink = '1'
            --v_ForwardALUToDriverRS1 := '1';
        elsif i_MemRD = i_InsnRS2 and i_MemRD /= 5x"0" then
            -- TODO: i_InsnRS2 might need to be the raw fetch output and not the register buffered value
            -- FIXME: if i_Branch = '1'
            --v_ForwardALUToDriverRS2 := '1';
        end if;

        -- Case a.iv:
        if i_MemRD = i_InsnRS1 and i_MemRD /= 5x"0" then
            -- TODO: i_InsnRS1 might need to be the raw fetch output and not the register buffered value
            -- FIXME: if i_Branch = '1' or i_JumpAndLink = '1'
            --v_ForwardMemToDriverRS1 := '1';
        elsif i_MemRD = i_InsnRS2 and i_MemRD /= 5x"0" then
            -- TODO: i_InsnRS2 might need to be the raw fetch output and not the register buffered value
            -- FIXME: if i_Branch = '1'
            --v_ForwardMemToDriverRS2 := '1';
        end if;


        o_ForwardALUToALUOperand1 <= v_ForwardALUToALUOperand1;
        o_ForwardALUToALUOperand2 <= v_ForwardALUToALUOperand2;

        o_ForwardMemToALUOperand1 <= v_ForwardMemToALUOperand1;
        o_ForwardMemToALUOperand2 <= v_ForwardMemToALUOperand2;

        o_ForwardMemToDriverRS1   <= v_ForwardMemToDriverRS1;
        o_ForwardMemToDriverRS2   <= v_ForwardMemToDriverRS2;

        o_ForwardALUToDriverRS1   <= v_ForwardALUToDriverRS1;
        o_ForwardALUToDriverRS2   <= v_ForwardALUToDriverRS2;
    end process;

end mixed;
   