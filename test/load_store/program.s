.text
.global _start

_start:
    li x11, 0  # Load address of test memory into x11
    li x10, 0  # x10 (a0) = Test case number

    # Test 1
    li x10, 1
    li x12, 0x12
    sb x12, 0(x11)
    lb x13, 0(x11)
    li x14, 0x12
    bne x13, x14, _fail

    # Test 2
    li x10, 2
    li x12, 0x92
    sb x12, 0(x11)
    lbu x13, 0(x11)
    li x14, 0x92
    bne x13, x14, _fail

    # Test 3
    li x10, 3
    li x12, 0x3456
    sh x12, 0(x11)
    lh x13, 0(x11)
    li x14, 0x3456
    bne x13, x14, _fail

    # Test 4
    li x10, 4
    li x12, 0xCDEF
    sh x12, 0(x11)
    lhu x13, 0(x11)
    li x14, 0xCDEF
    bne x13, x14, _fail

    # Test 5
    li x10, 5
    li x12, 0x12345678
    sw x12, 0(x11)
    lw x13, 0(x11)
    li x14, 0x12345678
    bne x13, x14, _fail

    # Test 6
    li x10, 6
    li x12, 0xAA
    sb x12, 0(x11)
    lh x13, 0(x11)
    li x14, 0x00AA
    bne x13, x14, _fail

    # Test 7
    li x10, 7
    li x12, 0xCC
    sb x12, 0(x11)
    lb x13, 0(x11)
    li x14, 0xFFFFFFCC
    bne x13, x14, _fail

    # Test 8
    li x10, 8
    li x12, 0x0000FFFF
    sh x12, 0(x11)
    lh x13, 0(x11)
    li x14, 0xFFFFFFFF
    bne x13, x14, _fail

    # Test 9
    li x10, 9
    lhu x13, 0(x11)
    li x14, 0x0000FFFF
    bne x13, x14, _fail

_pass:
    li x10, 0 # return 0 if there was no failure 
    li x1, 0x600D
_pass_done:
    j _pass_done


_fail:
    li x1, 0xDEAD
_fail_done:
    j _fail_done 
