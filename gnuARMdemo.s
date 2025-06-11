.arch armv5t
	.fpu softvfp
	.eabi_attribute 20, 1	; eabi接口属性
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"main.c"	; 当前汇编文件对应源文件名
	.text
	.global	global_val
	.data
	.align	2			;数据段对齐方式，2的2次方，即4字节对齐
	.type	global_val, %object
	.size	global_val, 4
global_val:
	.word	1			; 为global_val分配一个字（4字节）大小的存储空间，初始化为1
	.global	uninit_val	; 声明一个全局符号，名称为uninit_val
	.bss				; 切换到未初始化数据段
	.align	2
	.type	uninit_val, %object	; 设置全局符号的类型为变量
	.size	uninit_val, 4		; 设置全局符号的大小为4字节
uninit_val:              ; uninit_val标签，定义变量的开始位置
    .space  4           ; 在BSS段中分配4字节的空间，会被自动初始化为0
    .text               ; 切换到代码段，后面的内容将被放在.text段中
    .align  2           ; 代码段4字节对齐（2^2=4）
    .global add         ; 声明add为全局符号，使其可以被其他文件引用
    .syntax unified     ; 使用统一的ARM汇编语法
    .arm                ; 指定使用ARM指令集（不是Thumb）
    .type add, %function ; 声明add符号的类型为函数
    
add:                    ; add函数标签，函数入口点
    @ args = 0, pretend = 0, frame = 8      ; 编译器提示：无额外参数，栈帧大小为8字节
    @ frame_needed = 1, uses_anonymous_args = 0  ; 需要栈帧，不使用可变参数
    @ link register save eliminated.         ; 优化：无需保存lr寄存器（因为这是叶子函数）
    str fp, [sp, #-4]!  ; 保存旧的帧指针，预递减寻址（!表示先减后存）
    add fp, sp, #0      ; 设置新的帧指针，指向当前栈顶
    sub sp, sp, #12     ; 分配12字节的局部变量空间
    
    str r0, [fp, #-8]   ; 保存第一个参数到本地栈[fp-8]
    str r1, [fp, #-12]  ; 保存第二个参数到本地栈[fp-12]
    ldr r2, [fp, #-8]   ; 加载第一个参数到r2
    ldr r3, [fp, #-12]  ; 加载第二个参数到r3
    add r3, r2, r3      ; 执行加法运算，结果存在r3
    mov r0, r3          ; 将结果移到r0作为返回值
    
    add sp, fp, #0      ; 恢复栈指针
    @ sp needed         ; 编译器提示：需要恢复sp
    ldr fp, [sp], #4    ; 恢复帧指针，后递增寻址
    bx lr               ; 返回调用者（分支并切换状态）
    
    .size add, .-add    ; 设定add函数的大小（从add标签到当前位置）
    .align 2            ; 确保下一个函数4字节对齐
    .global sub         ; 声明sub函数为全局可见
    .syntax unified     ; 使用统一的ARM汇编语法
    .arm
    .type	sub, %function
sub:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-12]
	sub	r3, r2, r3
	mov	r0, r3
	add	sp, fp, #0
	@ sp needed
	ldr	fp, [sp], #4
	bx	lr
	.size	sub, .-sub
	.section	.rodata
	.align	2
.LC0:       ; 定义本地标签LC0，用于存储第一个格式化字符串
	.ascii	"a = %d\015\012\000"
	.align	2
.LC1:       ; 定义本地标签LC1，用于存储第二个格式化字符串
	.ascii	"b = %d\015\012\000"
	.text
	.align	2
	.global	main
	.syntax unified
	.arm
	.type	main, %function
main:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	mov	r1, #3
	mov	r0, #2
	bl	add
	str	r0, [fp, #-12]
	mov	r1, #4
	mov	r0, #5
	bl	sub
	str	r0, [fp, #-8]
	ldr	r1, [fp, #-12]
	ldr	r0, .L7
	bl	printf
	ldr	r1, [fp, #-8]
	ldr	r0, .L7+4
	bl	printf
	mov	r3, #0
	mov	r0, r3
	sub	sp, fp, #4
	@ sp needed
	pop	{fp, pc}
.L8:
	.align	2
.L7:
	.word	.LC0
	.word	.LC1
	.size	main, .-main
	.local	uninit_local.1
	.comm	uninit_local.1,4,4
	.data
	.align	2
	.type	local_val.0, %object
	.size	local_val.0, 4
local_val.0:
	.word	2
	.ident	"GCC: (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0"
	.section	.note.GNU-stack,"",%progbits