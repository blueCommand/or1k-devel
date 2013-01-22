	.file	"main.c"
	.section	.rodata
.LC0:
	.string	"Testing TLS constructs.."
.LC1:
	.string	"r10: %08x, r3: %08x, r13: %08x\n"
	.section .text
	.align	4
.proc	main
	.global main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	l.sw    	-8(r1),r2	 # SI store
	.cfi_offset 2, -8
	l.addi  	r2,r1,0 # addsi3
	.cfi_def_cfa_register 2
	l.sw    	-4(r1),r9	 # SI store
	l.addi	r1,r1,-20	# allocate frame
	.cfi_offset 9, -4
	l.movhi  	r3,hi(.LC0) # movsi_high
	l.ori   	r3,r3,lo(.LC0) # movsi_lo_sum
	l.jal   	puts # call_value_internal
	l.nop			# nop delay slot
#APP
# 11 "main.c" 1
	l.movhi   r3,tpoffhi(foo)
l.ori     r3,r3,tpofflo(foo)
l.add     r3,r3,r10
l.lwz     r3, 0(r3)

# 0 "" 2
#NO_APP
	l.movhi  	r3,hi(r10) # movsi_high
	l.ori   	r3,r3,lo(r10) # movsi_lo_sum
	l.lwz   	r5,0(r3)	 # SI load
	l.movhi  	r3,hi(r13) # movsi_high
	l.ori   	r3,r3,lo(r13) # movsi_lo_sum
	l.lwz   	r4,0(r3)	 # SI load
	l.movhi  	r3,hi(r3) # movsi_high
	l.ori   	r3,r3,lo(r3) # movsi_lo_sum
	l.lwz   	r3,0(r3)	 # SI load
	l.sw    	0(r1),r5	 # SI store
	l.sw    	4(r1),r4	 # SI store
	l.sw    	8(r1),r3	 # SI store
	l.movhi  	r3,hi(.LC1) # movsi_high
	l.ori   	r3,r3,lo(.LC1) # movsi_lo_sum
	l.jal   	printf # call_value_internal
	l.nop			# nop delay slot
.L2:
	l.j     	.L2 # jump_internal
	l.nop			# nop delay slot
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.local	r10
	.comm	r10,4,4
	.local	r13
	.comm	r13,4,4
	.local	r3
	.comm	r3,4,4
	.ident	"GCC: (GNU) 4.8.0 20121129 (experimental)"
