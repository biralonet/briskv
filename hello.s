    add x1, x0, x0
_loop:
    add x1, x1, 1
    jal x0, _loop
    ebreak
