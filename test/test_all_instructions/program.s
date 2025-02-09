_start:
    # Test ADDI (immediate addition)
    li x5, 0           # Load 0 into x5
    addi x5, x5, 5     # x5 = x5 + 5 (expect x5 = 5)
    li x6, 5           # Expected value
    li x2, 1
    bne x5, x6, fail   # Branch to fail if mismatch

    # Test ADD (register addition)
    li x7, 10
    add x7, x7, x6     # x7 = 10 + 5 (expect x7 = 15)
    li x8, 15
    li x2, 2
    bne x7, x8, fail

    # Test SUB (subtraction)
    li x9, 20
    sub x9, x9, x6     # x9 = 20 - 5 (expect x9 = 15)
    li x2, 3
    bne x9, x8, fail

    # Test AND, OR, XOR
    li x10, 0b1010
    li x11, 0b1100
    and x5, x10, x11   # x5 = 1010 & 1100 (expect 1000 = 8)
    li x6, 8
    li x2, 4
    bne x5, x6, fail

    or x5, x10, x11    # x5 = 1010 | 1100 (expect 1110 = 14)
    li x6, 14
    li x2, 5
    bne x5, x6, fail

    xor x5, x10, x11   # x5 = 1010 ^ 1100 (expect 0110 = 6)
    li x6, 6
    li x2, 6
    bne x5, x6, fail

    # Test Shift Operations
    li x10, 1
    sll x10, x10, 3    # x10 = 1 << 3 (expect 8)
    li x6, 8
    li x2, 7
    bne x10, x6, fail

    li x10, 16
    srl x10, x10, 2    # x10 = 16 >> 2 (expect 4)
    li x6, 4
    li x2, 8
    bne x10, x6, fail

    li x10, -16
    sra x10, x10, 2    # Arithmetic shift right (expect -4)
    li x6, -4
    li x2, 9
    bne x10, x6, fail

    # Test SLT and SLTU
    li x10, -1         # -1 is stored as all 1s (two's complement)
    li x11, 1
    slt x5, x10, x11   # x5 = (-1 < 1) ? 1 : 0 (expect 1)
    li x6, 1
    li x2, 10
    bne x5, x6, fail

    li x10, 0xFFFFFFFF # -1 in unsigned (largest unsigned)
    li x11, 1
    sltu x5, x10, x11  # Unsigned compare (-1 is large, expect 0)
    li x6, 0
    li x2, 11
    bne x5, x6, fail

    # Test Branch Instructions
    li x10, 5
    li x11, 5
    li x2, 12
    bne x10, x11, fail # Should NOT branch (pass expected)

    li x2, 13
    beq x10, x11, pass # Should branch (pass expected)

fail:
    li x1, 1           # Indicate failure (1 = failure)
    j loop

pass:
    li x1, 0           # Indicate success (0 = success)

loop:
    j loop             # Infinite loop
