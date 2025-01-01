.section .text
.global start

start:
	li a0, 0

.L0:
	addi a0, a0, 1
	call wait
	j .L0

	ebreak

wait:
	li a1, 1
	slli a1, a1, 18
.L1:
	addi a1, a1, -1
	bnez a1, .L1
	ret

