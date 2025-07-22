# UART协议编程

1，波特率BaudRate算时间：

- 115200波特率，表示传输 一个bit需要 1/115200（秒）
- 在“ 1 + 8 + 1 ” 的经典配置下，可以算出，传输 1个Byte 需要的时间是 (1/115200)*10秒 （一个数据帧就传输一个字节数据嘛）
- 则可以计算得到，传输速率为 11520 Byte/s
- 通信双方事先约定好一样的baud rate，一次保证数据传输正确，关键就是双方约定好每一位传输的时间

2，波特率：1秒内传输信号的状态数（波形数）      比特率：1秒内传输数据的bit数

- 如果一个波形，可以表示 N 个bit， 那么： 波特率 * N == 比特率

3，UART三种编程方式：查询、中断、DMA

- 数据传输涉及的三要素：源、目的、长度
- 其中DMA的效率最高

4，RS485电平：两线电压差为：+（2至6）V表示逻辑1， -（2至6）V表示逻辑0

- 是半双工的
- 电平转换芯片：MAX13487EESA
- 将TTL电平装欢成RS485电平
- TTL电平：3.3V 或 5V通常表示逻辑1，低电平接近 0V（通常≤0.8V）表示逻辑0

5，UART编程使用中断方式：

- 使用中断发送数据的流程...
- 当Tx完成或Rx完成会调用回调函数

```c
HAL_UART_Transmit_IT(&huart2, &c, 1);     // 开启中断，启动发送

只是记录这些数据的信息、提供一个回调函数、最后使能中断而已
huart->pTxBuffPtr  = pData;
huart->TxXferSize  = Size;
huart->TxXferCount = Size;
huart->TxISR       = NULL;

Rest some code ... 

else
{
    huart->TxISR = UART_TxISR_8BIT_FIFOEN;      // 发送完成后，会调用这个TxISR
}
/* Enable the Transmit Data Register Empty interrupt */
ATOMIC_SET_BIT(huart->Instance->CR1, USART_CR1_TXEIE_TXFNFIE);

后续都靠提供的ISR来实现（USARTx_IRQHandler）
void USART2_IRQHandler(void)
{
    Rest some code ... 
    HAL_UART_IRQHandler(&huart2);
    Rest some code ... 
}

```

- ![alt text](UART协议中断-3.png)
- 使用DMA来转发数据，也会在最后产生一个完成中断，最后还是会 调用 xxxRxCpltCallback()、xxxTxCpltCallback()

6，效率最高的UART编程方式：

- 要想保证读到的数据不丢失的话，我们需要在内存中开辟一个buf：我们需要将数据从硬件上读出来存在这个buf里面
  - 裸机：环形buffer
  - RTOS：队列queue
- 多任务系统里面一般不使用查询方式，对实时性影响大
- DMA（只会中断CPU一次、我们这里也配合使用FIFO） 和 中断（会中断N次CPU）的方式，都需要我们去执行到代码，才会开启数据传输，也不大好
- 所以我们引入空闲中断：Idle        （还能控制接收多少个字节，在）

```c
HAL_UARTEx_ReceiveToIdle_DMA(&huart4, g_uart4_rx_buf, 100); // 启动接收，期望得到100个数据，并存储到 g_uart4_rx_buf 中
                                                            // 如果确实收到100个数据，则会调用 xxxRxCpltCallback()
                                  
```

- 结合UART的数据帧，当检测到Tx发送空闲（持续高电平）时，会产生一个空闲中断
- 等待完成：就是等待某些变量的值改变
- UART中断编程方式没有必要使用空闲中断，本来就是每接收一个数据（u8或u16类型）就会产生一次中断...

- 接收：完成后调用 xxxCpltCallback(), xxxRxEventCallback()两个回调函数
  - xxxRxCpltCallback()：读取和转存数据（到内存...）、重新开启 DMA+IDLE  接收（下一次...）
  - xxxRxEventCallback()：行为同上
- 发送：完成后重新开启DMA发送

7，在RTOS中使用UART：

- 在一开始就开启 DMA+Idle中断 （任务创建时）
- 注意上述的种种回调函数都是在中断的上下文中执行的，所以使用RTOS的函数要使用带ISR的版本
- 此时的回调函数在进行“ 读取和转存数据（到内存...） ”时，是将数据发送到RTOS的队列（写队列）
  - 以后的应用程序就不直接操作串口了
  - 通过读队列得到数据
- 什么时候读取数据？什么时候写入数据？
  - 我们引入信号量来帮助我们
  - Take 和 Give

- 面向对象封装UART设备：
  - 使用结构体：

  ```c
  typedef struct UART_Device
  {
      char *name;
      int (*Init) (struct UART_Device *pDev, int baud, char parity, int data_bit, int stop_bit);
      int (*Send) (struct UART_Device *pDev, uint8_t *datas, uint32_t len, int timeout);
      int (*RecvByte) (struct UART_Device *pDev, uint8_t *data, int timeout);
  } UART_Device;
  ```

  - 结构体的初始化放到 底层驱动程序的实现中去
  - 封装底层，不暴露底层的操作函数
  - 在 具体的、底层的硬件驱动程序里面，构造好了“这些结构体”，那么在它的上层，就可以直接使用了

  ```c
  /* UART设备结构体初始化 */
  struct UART_Device g_uart2_dev = {"uart2", UART2_Rx_Start, UART2_Send, UART2_GetData};
  struct UART_Device g_uart4_dev = {"uart4", UART4_Rx_Start, UART4_Send, UART4_GetData};
  ```

  - 在上层简单 extern 一下就可以使用，或者 #include "xxx.h"

  ```c
  extern struct UART_Device g_uart2_dev;
  extern struct UART_Device g_uart4_dev;
  ```
