.text
.globl _start

_start:
    addi x5, x0, 0
    addi x6, x0, 1
loop:
    sw x5, 0(x7)
    addi x7, x7, 4
    add x10, x5, x6
    add x5, x0, x6
    add x6, x0, x10
    bne x11, x0, loop
end:
    ebreak
