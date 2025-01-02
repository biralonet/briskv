	/* code */
	.section .text
	.global start

start:
	li gp, 0x400000
	li a0, 0

	.L0:

	sw a0, 4(gp)
	call wait
	addi a0, a0, 1
	j .L0

	ebreak

wait:
	li t0, 1
	slli t0, t0, 22

	.L2:

	addi t0, t0, -1
	bnez t0, .L2
	ret
