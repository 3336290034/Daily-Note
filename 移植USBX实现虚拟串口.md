# USBX组件

1，`USBX`是`Azure RTOS`的一个核心组件，是一套高性能、可移植的嵌入式 USB 协议栈

- "栈"从何体现？
  -“协议栈”（Protocol Stack）中的 “栈”，源于计算机科学中 “栈（Stack）” 的`层次结构特性`
  - 底层支撑上层，上层依赖底层，类似 “堆叠” 的关系

- 以`USB协议栈`为例，它将复杂的USB通信功能拆分成多个分层，每层只负责特定任务，且仅与相邻的上下层交互（类似栈的FILO或层级依赖`栈帧`的逻辑）：
  - 物理层（最底层）：负责电气信号、接口定义（如 USB Type-A/C 接口的引脚、电压），是整个通信的 “硬件基础”
  - 链路层（中间层）：处理数据的封装与传输（如将数据拆分成 USB 包、校验错误、管理总线枚举），为上层提供 “可靠传输” 服务
  - 设备类层（最上层）：基于底层提供的传输能力，实现特定设备的功能逻辑（如 HID 层定义键盘如何发送按键码，CDC-ACM 层定义串口数据格式）
- 其他常见的协议栈（如 TCP/IP 协议栈）也遵循这种逻辑：`应用层 → 传输层 → 网络层 → 数据链路层 → 物理层`，每层依赖下层，形成 “栈” 式结构

2，USBX是一个包含完整Host、Device驱动程序的程序吗？所以我们叫它USB协议栈？

## USBX的层级结构

1，层级结构

- controler layer
  - HAL库实现
- stack layer
  - 实现通用代码：例如`描述符`的实现，`端点`的读写
  - stack、通用····联想一下stack，，，，
  - 核心部分
- class layer
  - CDC
  - MSC
  - HID
  - ···
- applications（看不到的部分）
  - 实现数据的传输、读写等

## 集成USBX到FreeRTOS

- 依旧是熟悉的回调函数

## MISC

1，创建一个USB设备之前，首先要做的是要去指定它的描述符，之后才是数据的读写
2，端点描述符咋确定方向的  --- 通过地址
3，如果PC无法识别出USB设备，程序就需要纠错了

## 一些术语

1，核心术语

- PCD：在`STM32 HAL`库的`USB驱动上下文`中，`PCD`是`USB Peripheral Controller Driver`的缩写，即 “USB 外设控制器驱动”
- CDC-ACM：Communication Device Class - Abstract Control Model，属于 USB 通信设备类（CDC）的子类，用于模拟串行通信接口（如虚拟串口）
  - 它通过抽象控制模型简化设备与主机的交互，常见于调制解调器、USB 转串口适配器等设备。例如，树莓派通过 CDC-ACM 实现 USB 转串口功能，允许主机通过串口工具直接通信。
- MSC：Mass Storage Class，大容量存储类，定义 U 盘、移动硬盘、SD 卡读卡器等存储设备的通信协议
  - 例如，Windows 系统自动识别 U 盘即基于 MSC 协议
- IAD：Interface Assocation Descriptor，接口关联描述符，用于将多个接口组合成一个功能单元
- 网络摄像头（UVC 设备）通常包含视频控制接口（VC）和视频流接口（VS），IAD 将这两个接口关联，使主机视为一个完整的视频设备

2，USB设备类：

- HID：Human Interface Device，人机接口设备类，定义键盘、鼠标、游戏手柄等输入设备的协议
- UVC：USB Video Class，视频设备类，用于网络摄像头、视频采集卡等
- DFU：Device Firmware Update，固件更新类，允许通过 USB 接口更新设备固件。例如，嵌入式设备（如开发板）常使用 DFU 模式进行程序烧录
- CDC：Communication Device Class，USB通信设备类
- Audio Class：音频设备类，涵盖麦克风、扬声器、声卡等。
  - 该类支持等时传输以保证音频流的连续性，例如 USB 耳机通过 Audio Class 实现数字音频传输
- Printer Class：打印机设备类，定义打印任务的通信协议
  - 例如，USB 激光打印机通过该类接收主机发送的打印指令和数据

3，其他扩展：

- PD：Power Delivery，USB 功率传输协议，支持快速充电和灵活供电（如 20V/5A 的 100W 快充）
- OTG：On-The-Go，允许设备在主机（Host）和外设（Device）模式间切换，例如手机可作为主机连接 U 盘，或作为外设连接电脑充电
