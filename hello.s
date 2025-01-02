	/* code */
	.section .text
	.global start

start:
	li a0, 0
	li s0, 0
	li s1, 16
	la s2, data

	.L0:

        lb a0, 0(s2)
	addi a1, a0, 0
	call wait

	li a0, 0
	call wait

	addi s2, s2, 1
	sb a1, 800(s2)
	lb a0, 800(s2)
	call wait

	addi s0, s0, 1
	bne s0, s1, .L0

	ebreak

wait:
	li t0, 1
	slli t0, t0, 22

	.L2:

	addi t0, t0, -1
	bnez t0, .L2
	ret

	/* memory */
	.section .data
data:
        .byte 0x04, 0x03, 0x02, 0x01
	.byte 0x08, 0x07, 0x06, 0x05
	.byte 0x0c, 0x0b, 0x0a, 0x09
	.byte 0xff, 0x0f, 0x0e, 0x0d

