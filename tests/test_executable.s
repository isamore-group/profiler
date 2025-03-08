	.text
	.file	"test.cpp"
	.section	.text.startup,"ax",@progbits
	.p2align	4, 0x90                         # -- Begin function __cxx_global_var_init
	.type	__cxx_global_var_init,@function
__cxx_global_var_init:                  # @__cxx_global_var_init
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -24
	movq	"bb_id___cxx_global_var_init:entry"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	leaq	_ZStL8__ioinit(%rip), %rbx
	movq	%rbx, %rdi
	callq	_ZNSt8ios_base4InitC1Ev@PLT
	movq	_ZNSt8ios_base4InitD1Ev@GOTPCREL(%rip), %rdi
	leaq	__dso_handle(%rip), %rdx
	movq	%rbx, %rsi
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	.cfi_def_cfa %rsp, 8
	jmp	__cxa_atexit@PLT                # TAILCALL
.Lfunc_end0:
	.size	__cxx_global_var_init, .Lfunc_end0-__cxx_global_var_init
	.cfi_endproc
                                        # -- End function
	.text
	.globl	_Z9fibonaccii                   # -- Begin function _Z9fibonaccii
	.p2align	4, 0x90
	.type	_Z9fibonaccii,@function
_Z9fibonaccii:                          # @_Z9fibonaccii
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -24
	movq	"bb_id__Z9fibonaccii:entry"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	movl	%edi, -12(%rbp)
	cmpl	$1, -12(%rbp)
	jg	.LBB1_2
# %bb.1:                                # %if.then
	movq	"bb_id__Z9fibonaccii:if.then"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	movl	-12(%rbp), %eax
	movl	%eax, -16(%rbp)
	jmp	.LBB1_3
.LBB1_2:                                # %if.end
	movq	"bb_id__Z9fibonaccii:if.end"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	movl	-12(%rbp), %edi
	subl	$1, %edi
	callq	_Z9fibonaccii
	movl	%eax, %ebx
	movl	-12(%rbp), %edi
	subl	$2, %edi
	callq	_Z9fibonaccii
	addl	%eax, %ebx
	movl	%ebx, -16(%rbp)
.LBB1_3:                                # %return
	movq	"bb_id__Z9fibonaccii:return"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	movl	-16(%rbp), %eax
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	.cfi_def_cfa %rsp, 8
	retq
.Lfunc_end1:
	.size	_Z9fibonaccii, .Lfunc_end1-_Z9fibonaccii
	.cfi_endproc
                                        # -- End function
	.globl	_Z9factoriali                   # -- Begin function _Z9factoriali
	.p2align	4, 0x90
	.type	_Z9factoriali,@function
_Z9factoriali:                          # @_Z9factoriali
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -24
	movq	"bb_id__Z9factoriali:entry"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	movl	%edi, -12(%rbp)
	cmpl	$1, -12(%rbp)
	jg	.LBB2_2
# %bb.1:                                # %if.then
	movq	"bb_id__Z9factoriali:if.then"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	movl	$1, -16(%rbp)
	jmp	.LBB2_3
.LBB2_2:                                # %if.end
	movq	"bb_id__Z9factoriali:if.end"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	movl	-12(%rbp), %ebx
	movl	-12(%rbp), %edi
	subl	$1, %edi
	callq	_Z9factoriali
	imull	%eax, %ebx
	movl	%ebx, -16(%rbp)
.LBB2_3:                                # %return
	movq	"bb_id__Z9factoriali:return"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	movl	-16(%rbp), %eax
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	.cfi_def_cfa %rsp, 8
	retq
.Lfunc_end2:
	.size	_Z9factoriali, .Lfunc_end2-_Z9factoriali
	.cfi_endproc
                                        # -- End function
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	pushq	%rbx
	pushq	%rax
	.cfi_offset %rbx, -24
	movq	"bb_id_main:entry"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	movl	$0, -12(%rbp)
	movq	_ZSt4cout@GOTPCREL(%rip), %rdi
	leaq	.L.str(%rip), %rsi
	callq	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	movq	%rax, %rbx
	movl	$10, %edi
	callq	_Z9fibonaccii
	movq	%rbx, %rdi
	movl	%eax, %esi
	callq	_ZNSolsEi@PLT
	movq	_ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_@GOTPCREL(%rip), %rsi
	movq	%rax, %rdi
	callq	_ZNSolsEPFRSoS_E@PLT
	movq	_ZSt4cout@GOTPCREL(%rip), %rdi
	leaq	.L.str.1(%rip), %rsi
	callq	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	movq	%rax, %rbx
	movl	$5, %edi
	callq	_Z9factoriali
	movq	%rbx, %rdi
	movl	%eax, %esi
	callq	_ZNSolsEi@PLT
	movq	_ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_@GOTPCREL(%rip), %rsi
	movq	%rax, %rdi
	callq	_ZNSolsEPFRSoS_E@PLT
	xorl	%eax, %eax
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	.cfi_def_cfa %rsp, 8
	retq
.Lfunc_end3:
	.size	main, .Lfunc_end3-main
	.cfi_endproc
                                        # -- End function
	.section	.text.startup,"ax",@progbits
	.p2align	4, 0x90                         # -- Begin function _GLOBAL__sub_I_test.cpp
	.type	_GLOBAL__sub_I_test.cpp,@function
_GLOBAL__sub_I_test.cpp:                # @_GLOBAL__sub_I_test.cpp
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	movq	"bb_id__GLOBAL__sub_I_test.cpp:entry"@GOTPCREL(%rip), %rax
	movb	$0, (%rax)
	popq	%rbp
	.cfi_def_cfa %rsp, 8
	jmp	__cxx_global_var_init           # TAILCALL
.Lfunc_end4:
	.size	_GLOBAL__sub_I_test.cpp, .Lfunc_end4-_GLOBAL__sub_I_test.cpp
	.cfi_endproc
                                        # -- End function
	.type	_ZStL8__ioinit,@object          # @_ZStL8__ioinit
	.local	_ZStL8__ioinit
	.comm	_ZStL8__ioinit,1,1
	.hidden	__dso_handle
	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"Fibonacci(10): "
	.size	.L.str, 16

	.type	.L.str.1,@object                # @.str.1
.L.str.1:
	.asciz	"Factorial(5): "
	.size	.L.str.1, 15

	.section	.init_array,"aw",@init_array
	.p2align	3, 0x0
	.quad	_GLOBAL__sub_I_test.cpp
	.type	"bb_id___cxx_global_var_init:entry",@object # @"bb_id___cxx_global_var_init:entry"
	.data
	.globl	"bb_id___cxx_global_var_init:entry"
	.p2align	4, 0x0
"bb_id___cxx_global_var_init:entry":
	.asciz	"__cxx_global_var_init:entry"
	.size	"bb_id___cxx_global_var_init:entry", 28

	.type	"bb_id__Z9fibonaccii:entry",@object # @"bb_id__Z9fibonaccii:entry"
	.globl	"bb_id__Z9fibonaccii:entry"
	.p2align	4, 0x0
"bb_id__Z9fibonaccii:entry":
	.asciz	"_Z9fibonaccii:entry"
	.size	"bb_id__Z9fibonaccii:entry", 20

	.type	"bb_id__Z9fibonaccii:if.then",@object # @"bb_id__Z9fibonaccii:if.then"
	.globl	"bb_id__Z9fibonaccii:if.then"
	.p2align	4, 0x0
"bb_id__Z9fibonaccii:if.then":
	.asciz	"_Z9fibonaccii:if.then"
	.size	"bb_id__Z9fibonaccii:if.then", 22

	.type	"bb_id__Z9fibonaccii:if.end",@object # @"bb_id__Z9fibonaccii:if.end"
	.globl	"bb_id__Z9fibonaccii:if.end"
	.p2align	4, 0x0
"bb_id__Z9fibonaccii:if.end":
	.asciz	"_Z9fibonaccii:if.end"
	.size	"bb_id__Z9fibonaccii:if.end", 21

	.type	"bb_id__Z9fibonaccii:return",@object # @"bb_id__Z9fibonaccii:return"
	.globl	"bb_id__Z9fibonaccii:return"
	.p2align	4, 0x0
"bb_id__Z9fibonaccii:return":
	.asciz	"_Z9fibonaccii:return"
	.size	"bb_id__Z9fibonaccii:return", 21

	.type	"bb_id__Z9factoriali:entry",@object # @"bb_id__Z9factoriali:entry"
	.globl	"bb_id__Z9factoriali:entry"
	.p2align	4, 0x0
"bb_id__Z9factoriali:entry":
	.asciz	"_Z9factoriali:entry"
	.size	"bb_id__Z9factoriali:entry", 20

	.type	"bb_id__Z9factoriali:if.then",@object # @"bb_id__Z9factoriali:if.then"
	.globl	"bb_id__Z9factoriali:if.then"
	.p2align	4, 0x0
"bb_id__Z9factoriali:if.then":
	.asciz	"_Z9factoriali:if.then"
	.size	"bb_id__Z9factoriali:if.then", 22

	.type	"bb_id__Z9factoriali:if.end",@object # @"bb_id__Z9factoriali:if.end"
	.globl	"bb_id__Z9factoriali:if.end"
	.p2align	4, 0x0
"bb_id__Z9factoriali:if.end":
	.asciz	"_Z9factoriali:if.end"
	.size	"bb_id__Z9factoriali:if.end", 21

	.type	"bb_id__Z9factoriali:return",@object # @"bb_id__Z9factoriali:return"
	.globl	"bb_id__Z9factoriali:return"
	.p2align	4, 0x0
"bb_id__Z9factoriali:return":
	.asciz	"_Z9factoriali:return"
	.size	"bb_id__Z9factoriali:return", 21

	.type	"bb_id_main:entry",@object      # @"bb_id_main:entry"
	.globl	"bb_id_main:entry"
"bb_id_main:entry":
	.asciz	"main:entry"
	.size	"bb_id_main:entry", 11

	.type	"bb_id__GLOBAL__sub_I_test.cpp:entry",@object # @"bb_id__GLOBAL__sub_I_test.cpp:entry"
	.globl	"bb_id__GLOBAL__sub_I_test.cpp:entry"
	.p2align	4, 0x0
"bb_id__GLOBAL__sub_I_test.cpp:entry":
	.asciz	"_GLOBAL__sub_I_test.cpp:entry"
	.size	"bb_id__GLOBAL__sub_I_test.cpp:entry", 30

	.ident	"clang version 18.1.8 (https://github.com/llvm/llvm-project 3b5b5c1ec4a3095ab096dd780e84d7ab81f3d7ff)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym _ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_
	.addrsig_sym _GLOBAL__sub_I_test.cpp
	.addrsig_sym _ZStL8__ioinit
	.addrsig_sym __dso_handle
	.addrsig_sym _ZSt4cout
