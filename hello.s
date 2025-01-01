add x10, x0, x0

_l0:
  addi x10, x10, 1
  jal x1, _wait
  jal x0, _l0
  ebreak

_wait:
  addi x11, x0, 1
  slli x11, x11, 18

_l1:
  addi x11, x11, -1
  bne x11, x0, _l1
  jalr x0, x1, 0
