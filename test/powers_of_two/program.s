_start:
    addi x1, x0, 0 # 0(x1) is address
    addi x2, x0, 1  # x2 is value
loop:
    sw x2, 0(x1)
    add x2, x2, x2
    addi x1, x1, 4 # stride is four bytes
    j loop