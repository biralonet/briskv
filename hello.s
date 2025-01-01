start:
  add x1, x0, x0
  add x2, x0, x0
  addi x2, x0, 63
loop:
  addi x1, x1, 1
  bne x1, x2, loop
  add x1, x0, x0
  jal x0, start
  ebreak
