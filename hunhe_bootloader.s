/* 
 * startup.s - Cortex-M4处理器的启动文件
 * 这个文件负责处理器启动时的底层初始化工作
 */

/* 指定汇编器的基本设置 */
.syntax unified        /* 使用统一的ARM语法 */
.cpu cortex-m4        /* 指定目标处理器为Cortex-M4 */
.thumb               /* 使用Thumb指令集 */

/* 声明全局符号，使其他文件可以访问 */
.global _start        /* 程序入口点 */
.global _stack_top    /* 栈顶位置 */

/* 
 * 中断向量表
 * Cortex-M处理器要求在内存起始位置放置中断向量表
 * 向量表中存储了各种中断的处理函数地址
 */
.section .vectors    /* 定义一个新的段 */
    .word   _stack_top          /* 复位后的栈顶指针初始值 */
    .word   Reset_Handler       /* 复位中断处理函数 */
    .word   NMI_Handler        /* 不可屏蔽中断处理函数 */
    .word   HardFault_Handler  /* 硬件错误处理函数 */
    /* 其他中断向量... */

/* 
 * 复位处理函数
 * 这是处理器复位后最先执行的代码
 * 负责系统的基本初始化工作
 */
.section .text       /* 代码段开始 */
Reset_Handler:
    /* 
     * 设置栈指针
     * 将栈顶地址加载到SP寄存器
     */
    ldr     sp, =_stack_top
    
    /* 
     * 初始化数据段
     * 将已初始化的全局变量从Flash复制到RAM
     * r0 = 数据段在RAM中的起始地址
     * r1 = 数据在Flash中的存储位置
     * r2 = 数据段在RAM中的结束地址
     */
    ldr     r0, =__data_start__
    ldr     r1, =__data_load__
    ldr     r2, =__data_end__
    cmp     r0, r1          /* 检查是否需要复制 */
    beq     .Lno_data_init  /* 如果起始地址相同，不需要复制 */
    
.Ldata_init:
    /* 
     * 数据复制循环
     * 每次复制4字节数据
     * [r1], #4 表示使用后自增4
     */
    ldr     r3, [r1], #4    /* 从Flash读取4字节 */
    str     r3, [r0], #4    /* 写入到RAM，并将地址+4 */
    cmp     r0, r2          /* 检查是否到达结束地址 */
    bne     .Ldata_init     /* 如果未完成，继续循环 */
    
.Lno_data_init:
    /* 
     * 初始化BSS段
     * BSS段存储未初始化的全局变量
     * 需要将其清零
     */
    ldr     r0, =__bss_start__  /* BSS段起始地址 */
    ldr     r1, =__bss_end__    /* BSS段结束地址 */
    mov     r2, #0              /* 要填充的值（0） */
    
.Lbss_init:
    /* 
     * BSS段清零循环
     * 每次清零4字节
     */
    str     r2, [r0], #4    /* 存储0，并将地址+4 */
    cmp     r0, r1          /* 检查是否到达结束地址 */
    bne     .Lbss_init      /* 如果未完成，继续循环 */
    
    /* 
     * 调用C语言的系统初始化函数
     * 通常用于设置时钟、外设等
     */
    bl      SystemInit
    
    /* 
     * 调用C语言的main函数
     * 此时C运行环境已经准备就绪
     */
    bl      main
    
    /* 
     * 安全循环
     * 如果main函数返回，进入无限循环
     * 防止程序跑飞
     */
.Lloop:
    b       .Lloop          /* 无限循环 */

/* 
 * 中断处理函数
 * 这里使用最简单的实现方式
 * 在实际应用中应该有更复杂的处理逻辑
 */
NMI_Handler:           /* 不可屏蔽中断处理 */
HardFault_Handler:     /* 硬件错误处理 */
    b       .          /* 死循环，停在当前位置 */

/* 
 * 栈空间定义
 * 分配4KB(0x1000)的栈空间
 * 在链接脚本中，这个段应该被放置在RAM区域
 */
.section .stack
    .space  0x1000     /* 分配4KB栈空间 */
_stack_top:            /* 栈顶标记 */