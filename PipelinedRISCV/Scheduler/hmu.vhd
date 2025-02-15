-------------------------------------------------------------------------
-- Connor Link
-- Iowa State University
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- hmu.vhd
-- DESCRIPTION: This file contains an implementation of a basic RISC-V hazard management unit.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.RISCV_types.all;

entity hmu is
    port(
        i_MaskStall    : in  std_logic;

        i_InsnRS1      : in  std_logic_vector(4 downto 0);
        i_InsnRS2      : in  std_logic_vector(4 downto 0);

        i_DriverRS1    : in  std_logic_vector(4 downto 0);
        i_DriverRS2    : in  std_logic_vector(4 downto 0);
        i_DriverRD     : in  std_logic_vector(4 downto 0);
        i_DriverIsLoad : in  std_logic; -- the instruction a load instruction (this could cause a read-after-write hazard)

        i_ALURD        : in  std_logic_vector(4 downto 0);

        i_BranchMode   : in  natural;
        i_Branch       : in  std_logic; -- indicate if the branch is taken or not (hooks to output of BGU)
        i_IsBranch     : in  std_logic;


        o_Break        : out std_logic; -- stop the instruction pointer upcounter, will need to be ORed with the break signal off the driver!

        o_InsnFlush    : out std_logic;
        o_InsnStall    : out std_logic;

        o_DriverFlush  : out std_logic;
        o_DriverStall  : out std_logic
    );
end hmu;

architecture mixed of hmu is

begin
    
    process(
        i_InsnRS1,   i_InsnRS2,
        i_DriverRS1, i_DriverRS2, i_DriverRD, i_DriverIsLoad,
        i_ALURD,
        i_BranchMode, i_Branch, i_IsBranch
    )
        variable v_Break : std_logic := '0';

        variable v_InsnFlush : std_logic := '0';
        variable v_InsnStall : std_logic := '0';
        
        variable v_DriverFlush : std_logic := '0';
        variable v_DriverStall : std_logic := '0';

    begin
        -- Detect jal/j, which doesn't rely on any external data to execute, but will need to clear the pipeline until the remaining instructions are committed
        if i_BranchMode = work.RISCV_types.JAL_OR_BCC and i_IsBranch = '0' then
            -- No extra dependencies, so branch is computed taken; bubble a NOP
            v_InsnFlush := '1';
        end if;

        -- Detect jalr/jr, which relies on the source register for the branch target
        if i_BranchMode = work.RISCV_types.JALR then
            if (i_InsnRS1 = i_DriverRD and i_InsnRS1 /= 5x"0") or
               (i_InsnRS2 = i_DriverRD and i_InsnRS2 /= 5x"0") then
                v_Break := '1';
                -- FIXME: also insn flush?
                v_InsnStall := '1';
                v_DriverFlush := '1';
            end if;
        end if;

        -- Detect Bcc, which relies on two registers
        if i_BranchMode = work.RISCV_types.JAL_OR_BCC and i_IsBranch = '1' then
            if (i_InsnRS1 = i_DriverRD and i_InsnRS2 /= 5x"0") or
               (i_InsnRS2 = i_DriverRD and i_InsnRS2 /= 5x"0") then
                v_Break := '1';
                -- FIXME: also insn flush?
                v_InsnStall := '1';
                v_DriverFlush := '1';
            elsif i_Branch = '1' then
                -- Branch has no unresolved dependencies and is computed taken; bubble a NOP
                v_InsnFlush := '1';
            end if;
        end if;

        -- Detect load-use hazard, which will require a NOP bubble to resolve
        if i_DriverIsLoad = '1' and (i_DriverRS1 = i_ALURD or i_DriverRS2 = i_ALURD) then 
            v_Break := '1';
            -- FIXME: also insn flush?
            v_InsnStall := '1';
            v_DriverFlush := '1';
        end if;

        -- reset the stall signal once we have branched to start fetching new instructions
        -- NOTE: this is taking place after setting the control signals to override anything else
        if i_MaskStall = '1' then
            v_Break := '0';
            report "PIPELINE STALL RESCINDED" severity note;
        end if;

        o_Break <= v_Break;
        o_InsnFlush <= v_InsnFlush;
        o_InsnStall <= v_InsnStall;
        o_DriverFlush <= v_DriverFlush;
        o_DriverStall <= v_DriverStall;
    end process;

end mixed;
