add x0, x0, x0
add x1, x0, x0
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
addi x1, x1, 1
add x2, x1, x0
add x3, x1, x2
srli x3, x3, 3
slli x3, x3, 31
srai x3, x3, 5
srli x1, x3, 26
ebreak
