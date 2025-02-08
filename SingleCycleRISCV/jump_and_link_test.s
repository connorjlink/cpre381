_start:
    lui x5, %hi(jal_target)
    addi x5, x5, %lo(jal_target)
    jal x1, jal_target
    addi x6, x0, 0xDED # should not be executed

jal_target:
    addi x11, x0, 0x123
    lui x7, %hi(jalr_target)
    addi x7, x7, %lo(jalr_target)
    jalr x1, 0(x7)
    addi x6, x0, 0xF0F # should not be executed

jalr_target:
    addi x10, x0, 0x456

loop:
    beq x0, x0, loop