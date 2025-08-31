# 升级流程

1，上位机发送命令让目标板进入Bootloader模式
2，上位机发送文件给中控，中控看情况是否转发

一边接收一边烧写，因为单片机的内存不够大呀，烧写完还得写配置信息，在Flash的末尾
接收完毕上位机就发送命令，就进入App状态

如何进入“状态”呢？
通过写配置信息，程序会根据配置信息

如何实现上述的命令呢？

- 可以在中控或者传感器上面实现一个 寄存器
  - 这个寄存器读写的内容要能分辨是bootloader还是App
  - 所以选择通过实现一个AO寄存器（modbus中的四类寄存器），进而实现上述的功能
  
- 略低效率，但是开发简单的方式

判断当期程序是bootloader还是app

```c
int isBootloader(void)
{
    uint32_t link_addr = (uint32_t)isBootloader;
    if (link_addr < APP_LOAD_ADDR)
        return 1;
    else
        return 0;
}
```

## STM32F030的Bootloader

- 首先，补充：应用程序开头的是异常向量表
- 它并不像H5一样，它里面没有VTOR寄存器
- 实现异常向量表的重定向：
  - 对于F030，它的异常向量表的地址永远是地址0，当然这种说法是对于CPU而言的：在CPU眼里，异常向量表永远都是从0地址开始的
  - 很奇怪的是，F030的逻辑地址0可以映射到地址0x08000000，但是不可以映射到地址0x08200000
  - But，We Can让它映射到RAM的0x20000000地址，所以说对于F030来说，要从bootloader切换到应用程序，必须
    - 将异常向量表复制拷贝到RAM（我们选择空出前200个字节，足够异常向量表使用了）
    - 将0地址映射到地址0x20000000（异常向量表  --->  RAM），这样就从逻辑上实现了异常向量表的重定向
  - 这也就意味着，在内存里有一块区域是不能使用的，因为它被用来存放映射的应用程序的代码和数据
    - 这就需要我们自己在keil上面去操作了：空出前200个字节

## STM32H5处理启动命令（过程）（F030类似）

1，主循环

```c
    for (;;) {
        do {
            rc = modbus_receive(ctx, query);
            /* Filtered queries return 0 */
        } while (rc == 0);
 
        /* The connection is not closed on errors which require on reply such as
           bad CRC in RTU. */
        if (rc < 0 ) {
            /* Quit */
            continue;
        }

        err = process_emergency_cmd(ctx, query, rc, mb_mapping);
        if (err)
        {
            modbus_reply_exception(ctx, query, MODBUS_EXCEPTION_SLAVE_OR_SERVER_BUSY);
            continue;
        }
        
        err = process_file_record(query, rc);
        if (err)
        {
            modbus_reply_exception(ctx, query, MODBUS_EXCEPTION_SLAVE_OR_SERVER_BUSY);
            continue;
        }
        
        rc = modbus_reply(ctx, query, rc, mb_mapping);
        if (rc == -1) {
            //break;
        }
    }
```

2，process_emergency_cmd()函数

```c
static int process_emergency_cmd(modbus_t *ctx, uint8_t *msg, uint16_t msg_len, modbus_mapping_t *mb_mapping)
{    
    int count = get_point_map_count();
    int i;
    PChannelInfo ptChannelInfo;
    int reg_addr_master;
    int val;
    int write = 1;
    PPointMap ptPointMap = NULL;
    int err = 0;
    static int cnt = 0;
    char buf[100];

    reg_addr_master = ((uint16_t)msg[2]<<8) | msg[3];
    val             = ((uint16_t)msg[4]<<8) | msg[5];
    
    /* 只处理写操作 */
    if (msg[1] != MODBUS_FC_WRITE_SINGLE_REGISTER)
    {
        return 0;
    }

    /* 找到映射的点 */
    for (i = 0; i < count; i++)
    {
        if (g_tPointMaps[i].reg_addr_master == reg_addr_master && !strcmp(g_tPointMaps[i].reg_type, "4x"))
        {
            ptPointMap = &g_tPointMaps[i];
            break;
        }
    }

    if (!ptPointMap)
        return 0;

    /* 如果不是CMD_STATUS寄存器直接返回 */
    if ((ptPointMap->reg_addr_salve != MODBUS_UPDATE_REG_ADDR))
        return 0;
    
    /* 对于中控: 直接操作 */
    if (ptPointMap->channel == 0)
    {
        if (val == MODBUS_PRIVATE_CMD_ENTER_BOOT)
        {
            if (!isBootloader())
            {
                /* 复位之后就无法回复了,所以我们先回复 */
                modbus_reply(ctx, msg, msg_len, mb_mapping);
                ResetToBootloader();
                return -1;
            }
            return 0;
        }
        else if (val == MODBUS_PRIVATE_CMD_ENTER_APP)
        {
            /* 复位之后就无法回复了,所以我们先回复 */
            modbus_reply(ctx, msg, msg_len, mb_mapping);
            ResetToApplication();
            return -1;
        }
    }
    else
    {
        if (val == MODBUS_PRIVATE_CMD_ENTER_BOOT)
            SetUpdateStatus(1);
        
        /* 对于外接的传感器,直接下发命令 */
        ptChannelInfo = get_channelinfo(ptPointMap->channel);
        if (!ptChannelInfo->ctx)
            return 0;

        err = modbus_write_point(ptChannelInfo->ctx, ptPointMap, val);
        sprintf(buf, "modbus_write_point reg %d, val = 0x%x, err = %d, cnt = %d", ptPointMap->reg_addr_salve, val, err, cnt++);
        Draw_String(0, 228, buf, 0xff0000, 0);

        /* 出错或升级完毕 */
        if (err || (val == MODBUS_PRIVATE_CMD_ENTER_APP))
        {
            SetUpdateStatus(0);
        }
        
        return err;
    }

    return 0;
}
```

3，ResetToBootloader()函数

```c
void ResetToBootloader(void)
{
    FirmwareInfo tFirmwareInfo;

    memset(&tFirmwareInfo, 0xff, sizeof(FirmwareInfo));
    GetLocalFirmwareInfo(&tFirmwareInfo);

    tFirmwareInfo.bEnterBootloader = 1;
    WriteFirmwareInfo(&tFirmwareInfo);

    SoftReset();
}
```

4，ResetToApplication()函数

```c
void ResetToApplication(void)
{
    FirmwareInfo tFirmwareInfo;

    memset(&tFirmwareInfo, 0xff, sizeof(FirmwareInfo));
    GetLocalFirmwareInfo(&tFirmwareInfo);

    tFirmwareInfo.bEnterBootloader = 0;
    WriteFirmwareInfo(&tFirmwareInfo);

    SoftReset();
}

- 重启进入bootloader，重启进入Application，都是先写配置信息，再软复位
```

- 处理命令的过程

```c
     H5先 modbus_receive()
PC  --->  STM32H5  --->  process_emergency_cmd()  --->  modbus_write_point()  --->  STM32F030  --->  modbus_reply()  --->  ResetToxxx()
                                                                                                           |
                                                                                                           |
                                                                                                           ↓
                                                                                                        STM32H5  --->  modbus_reply()  --->  PC
STM32F030receive收到对于的数据后，也调用相同名字的process函数，写命令或者写文件
```

- 处理文件的过程

```c
     H5先 modbus_receive()
PC  --->  STM32H5  --->  process_file_record()  --->  send_firmware_to_device()  --->  STM32F030  --->  modbus_reply()  --->  ResetToxxx()
                                                                                                            |
                                                                                                            |
                                                                                                            ↓
                                                                                                         STM32H5  --->  modbus_reply()  --->  PC
STM32F030receive收到对于的数据后，也调用相同名字的process函数，写命令或者写文件
```
