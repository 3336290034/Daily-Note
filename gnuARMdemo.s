.arch armv5t
	.fpu softvfp
	.eabi_attribute 20, 1	; eabi�ӿ�����
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 6
	.eabi_attribute 34, 0
	.eabi_attribute 18, 4
	.file	"main.c"	; ��ǰ����ļ���ӦԴ�ļ���
	.text
	.global	global_val
	.data
	.align	2			;���ݶζ��뷽ʽ��2��2�η�����4�ֽڶ���
	.type	global_val, %object
	.size	global_val, 4
global_val:
	.word	1			; Ϊglobal_val����һ���֣�4�ֽڣ���С�Ĵ洢�ռ䣬��ʼ��Ϊ1
	.global	uninit_val	; ����һ��ȫ�ַ��ţ�����Ϊuninit_val
	.bss				; �л���δ��ʼ�����ݶ�
	.align	2
	.type	uninit_val, %object	; ����ȫ�ַ��ŵ�����Ϊ����
	.size	uninit_val, 4		; ����ȫ�ַ��ŵĴ�СΪ4�ֽ�
uninit_val:              ; uninit_val��ǩ����������Ŀ�ʼλ��
    .space  4           ; ��BSS���з���4�ֽڵĿռ䣬�ᱻ�Զ���ʼ��Ϊ0
    .text               ; �л�������Σ���������ݽ�������.text����
    .align  2           ; �����4�ֽڶ��루2^2=4��
    .global add         ; ����addΪȫ�ַ��ţ�ʹ����Ա������ļ�����
    .syntax unified     ; ʹ��ͳһ��ARM����﷨
    .arm                ; ָ��ʹ��ARMָ�������Thumb��
    .type add, %function ; ����add���ŵ�����Ϊ����
    
add:                    ; add������ǩ��������ڵ�
    @ args = 0, pretend = 0, frame = 8      ; ��������ʾ���޶��������ջ֡��СΪ8�ֽ�
    @ frame_needed = 1, uses_anonymous_args = 0  ; ��Ҫջ֡����ʹ�ÿɱ����
    @ link register save eliminated.         ; �Ż������豣��lr�Ĵ�������Ϊ����Ҷ�Ӻ�����
    str fp, [sp, #-4]!  ; ����ɵ�ָ֡�룬Ԥ�ݼ�Ѱַ��!��ʾ�ȼ���棩
    add fp, sp, #0      ; �����µ�ָ֡�룬ָ��ǰջ��
    sub sp, sp, #12     ; ����12�ֽڵľֲ������ռ�
    
    str r0, [fp, #-8]   ; �����һ������������ջ[fp-8]
    str r1, [fp, #-12]  ; ����ڶ�������������ջ[fp-12]
    ldr r2, [fp, #-8]   ; ���ص�һ��������r2
    ldr r3, [fp, #-12]  ; ���صڶ���������r3
    add r3, r2, r3      ; ִ�мӷ����㣬�������r3
    mov r0, r3          ; ������Ƶ�r0��Ϊ����ֵ
    
    add sp, fp, #0      ; �ָ�ջָ��
    @ sp needed         ; ��������ʾ����Ҫ�ָ�sp
    ldr fp, [sp], #4    ; �ָ�ָ֡�룬�����Ѱַ
    bx lr               ; ���ص����ߣ���֧���л�״̬��
    
    .size add, .-add    ; �趨add�����Ĵ�С����add��ǩ����ǰλ�ã�
    .align 2            ; ȷ����һ������4�ֽڶ���
    .global sub         ; ����sub����Ϊȫ�ֿɼ�
    .syntax unified     ; ʹ��ͳһ��ARM����﷨
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
.LC0:       ; ���屾�ر�ǩLC0�����ڴ洢��һ����ʽ���ַ���
	.ascii	"a = %d\015\012\000"
	.align	2
.LC1:       ; ���屾�ر�ǩLC1�����ڴ洢�ڶ�����ʽ���ַ���
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