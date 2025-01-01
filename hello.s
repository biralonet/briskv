    add x1, x0, x0
    addi x2, x0, 32
_loop:
    addi x1, x1, 1
    bne x1, x2, _loop
    ebreak
