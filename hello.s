	/* code */
	.section .text
	.global start

start:
	li s0, 0
	li s1, 16

	.L0:

	la t1, data
	add t1, t1, s0
	lb a0, 0(t1)
	call wait
	addi s0, s0, 1
	bne s0, s1, .L0
	ebreak

wait:
	li t0, 1
	slli t0, t0, 24
	.L1:

	addi t0, t0, -1
	bnez t0, .L1
	ret

	/* memory */
	.section .data
data:
        .byte 0x04, 0x03, 0x02, 0x01
        .byte 0x08, 0x07, 0x06, 0x05
        .byte 0x0c, 0x0b, 0x0a, 0x09
        .byte 0xff, 0x0f, 0x0e, 0x0d

