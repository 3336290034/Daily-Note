# 传感器设计_基于Modbus

1，首先要确定他的设备地址是多少？

- 使用libmodbus库，需要先给从设备分配buf，buf包含 [起始地址、个数]
- 4类寄存器，其实就是内存buf而已
  - 如何确定这4类寄存器的 起始地址、个数、？

- 比如一个开关量模块：
- 有 3 个LED、有 2 个继电器
- 即：有 5 个可读可写的位寄存器，即Digital Output（DO）
- 那么我去分配寄存器地址的时候
  - DO（位寄存器）分配数量为 5 个
  - 起始地址从 0 开始

- 用户按键 3 个
- 即：有 3 个只读的位寄存器，即Digital Input（DI）
- 那么我去分配寄存器地址的时候
  - DI（位寄存器）分配数量为 3 个
  - 起始地址从 0 开始

- 所以起始地址是由`你`决定的
- 个数是由`硬件`决定的
- 寄存器的分配，也是看硬件来决定，有些用不到的就不分配了

2，这些寄存器的功能是什么？

- 或者说，你要读写的值，有什么含义？ 值来自于哪里？
  - 值的含义
  - R：值的来源
  - W：值如何操作硬件

- 比如上述的开关量模块：
- 读DO寄存器时，读到 0或者1 的含义，是由`你`决定的
- 写也是同理
  - 所以，我们还需要规定 值 与 实际物理量 之间的转换关系

3，上述的寄存器如何与硬件建立联系

- 点表的设计
  - 点 == 寄存器（4类）
  - 即指定这些‘点’的功能、含义
- 要注意每个传感器的地址：
  - 先看设备的ID
  - 每个ID下的地址是不相关的
  