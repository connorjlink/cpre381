addi x25, x0, 0   # Load &A into x25
addi x26, x0, 256 # Load &B into x26
lw x1, 0(x25)     # Load A[0] into x1
lw x2, 4(x25)     # Load A[1] into x2
add x1, x1, x2    # x1 = x1 + x2
sw x1, 0(x26)     # Store x1 into B[0]
lw x2, 8(x25)     # Load A[2] into x2
add x1, x1, x2    # x1 = x1 + x2
sw x1, 4(x26)     # Store x1 into B[1]
lw x2, 12(x25)    # Load A[3] into x2
add x1, x1, x2    # x1 = x1 + x2
sw x1, 8(x26)     # Store x1 into B[2]
lw x2, 16(x25)    # Load A[4] into x2
add x1, x1, x2    # x1 = x1 + x2
sw x1, 12(x26)    # Store x1 into B[3]
lw x2, 20(x25)    # Load A[5] into x2
add x1, x1, x2    # x1 = x1 + x2
sw x1, 16(x26)    # Store x1 into B[4]
lw x2, 24(x25)    # Load A[6] into x2
add x1, x1, x2    # x1 = x1 + x2
addi x27, x0, 512 # Load &B[64] into x27
sw x1, -4(x27)    # Store x1 into B[63]
nop
