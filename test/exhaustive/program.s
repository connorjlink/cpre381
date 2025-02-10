.text
.global _start

_start:
    # Test LUI (Load Upper Immediate)
    li x31, 1              # Test number 1
    lui x1, 0x12345
    li x2, 0x12345000
    bne x1, x2, fail

    # Test AUIPC (Add Upper Immediate to PC)
    li x31, 2              # Test number 2
    auipc x3, 0x1
    addi x3, x3, -4        # Adjust to match expected value
    li x4, 0x1000
    and x3, x3, x4         # Mask relevant bits
    bne x3, x4, fail

    # Test ADDI (Add Immediate)
    li x31, 3              # Test number 3
    li x5, 10
    addi x5, x5, 5
    li x6, 15
    bne x5, x6, fail

    # Test SUBI (Sub Immediate, not standard in RISC-V, replaced with ADDI negative)
    li x31, 4              # Test number 4
    li x7, 20
    addi x7, x7, -8
    li x8, 12
    bne x7, x8, fail

    # Test SLTI (Set Less Than Immediate)
    li x31, 5
    li x9, 5
    slti x9, x9, 10
    li x1, 1
    bne x9, x1, fail
    li x9, 10
    slti x9, x0 10
    bne x9, x1, fail

    # Test SLTIU (Set Less Than Immediate Unsigned)
    li x31, 6
    li x10, -1  # 0xFFFFFFFF (unsigned large value)
    sltiu x10, x10, 1
    bne x10, x0, fail

    # Test XORI
    li x31, 7
    li x11, 0xFFFF0000
    xori x11, x11, -1
    li x12, 0x0000FFFF
    bne x11, x12, fail

    # Test ORI
    li x31, 8
    li x13, 0x0000FF00
    ori x13, x13, 0x0FF
    li x14, 0x0000FFFF
    bne x13, x14, fail

    # Test ANDI
    li x31, 9
    li x15, 0x0F0F
    andi x15, x15, 0x000F
    li x16, 0x000F
    bne x15, x16, fail

    # Test SLLI (Shift Left Logical Immediate)
    li x31, 10
    li x17, 1
    slli x17, x17, 4
    li x18, 16
    bne x17, x18, fail

    # Test SRLI (Shift Right Logical Immediate)
    li x31, 11
    li x19, 16
    srli x19, x19, 4
    li x20, 1
    bne x19, x20, fail

    # Test SRAI (Shift Right Arithmetic Immediate)
    li x31, 12
    li x21, -16
    srai x21, x21, 2
    li x22, -4
    bne x21, x22, fail

    # Test ADD (Add Register)
    li x31, 13
    li x23, 5
    li x24, 7
    add x25, x23, x24
    li x26, 12
    bne x25, x26, fail

    # Test SUB (Subtract Register)
    li x31, 14
    sub x27, x25, x23
    li x28, 7
    bne x27, x28, fail

    # Test SLL (Shift Left Logical Register)
    li x31, 15
    sll x29, x1, x0
    bne x29, x1, fail

    # Test SLT (Set Less Than Register)
    li x31, 16
    li x1, 5
    li x2, 10
    slt x3, x1, x2
    li x1, 1
    bne x3, x1, fail

    # Test SLTU (Set Less Than Unsigned Register)
    li x31, 17
    li x1, -1
    li x2, 1
    sltu x3, x1, x2
    bne x3, x0, fail

    # Test XOR
    li x31, 18
    li x1, 0xFF00
    li x2, 0x00FF
    xor x3, x1, x2
    li x4, 0xFFFF
    bne x3, x4, fail

    # Test OR
    li x31, 19
    li x1, 0xF0F0
    li x2, 0x0F0F
    or x3, x1, x2
    li x4, 0xFFFF
    bne x3, x4, fail

    # Test AND
    li x31, 20
    li x1, 0xF0F0
    li x2, 0x0F0F
    and x3, x1, x2
    li x4, 0x0000
    bne x3, x4, fail

# Test Load and Store Instructions
    li x31, 21
    li x1, 0x12345678
    sw x1, 0(x0)
    lb x2, 0(x0)
    li x3, 0x78 # FIXME: figure out what our endianness is in the memory storage
    bne x2, x3, fail

    li x31, 22
    lh x2, 0(x0)
    li x3, 0x5678
    bne x2, x3, fail

    li x31, 23
    lw x2, 0(x0)
    li x3, 0x12345678
    bne x2, x3, fail

    li x31, 24
    li x3, 0xAB
    sb x3, 4(x0)
    lbu x2, 4(x0)
    bne x2, x3, fail

    # Test Branch Instructions
    li x31, 25
    li x1, 5
    li x2, 5
    beq x1, x2, branch_pass
    j fail
branch_pass:
    li x31, 26
    li x1, 5
    li x2, 10
    bne x1, x2, branch_pass2
    j fail
branch_pass2:
    li x31, 27
    li x1, 5
    li x2, 10
    blt x1, x2, branch_pass3
    j fail
branch_pass3:
    li x31, 28
    li x1, 10
    li x2, 5
    bge x1, x2, branch_pass4
    j fail
branch_pass4:
    li x31, 29
    li x1, 1
    li x2, 2
    bltu x1, x2, branch_pass5
    j fail
branch_pass5:
    li x31, 30
    li x1, 2
    li x2, 1
    bgeu x1, x2, branch_done
    j fail

branch_done:
    # If all tests pass, loop indefinitely
    j success

fail:
    li x30, 0xDEADBEEF  # Indicate failure
fail_done:
    j fail_done              # Loop on failure

success:
    li x31, 0x600D
success_done:
    j success_done           # Loop indefinitely on success
