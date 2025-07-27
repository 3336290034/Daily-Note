# libmodbus

2，<https://www.doubao.com/thread/w7c73d8e185772b90>

## 核心函数调用过程---大框架

1，试想这样一个场景：一个Modbus主设备通过COM1访问从设备1和2、通过COM1访问从设备1和2，那我们该如何描述这不同的硬件框架呢？

- 对不同的总线（数据链路），分别抽象出不同的modbus_t结构体
  - Modbus结构体：

  ```c
  typedef struct _modbus modbus_t;

  struct _modbus {
    /* Slave address */
    int slave;
    /* Socket or file descriptor */
    int s;

    int debug;
    int error_recovery;
    int quirks;
    struct timeval response_timeout;
    struct timeval byte_timeout;
    struct timeval indication_timeout;
    const modbus_backend_t *backend;
    void *backend_data;
    };
    最后一个 modbus_backend_t 描述了modbus通信的后端实现：“是用的串口？还是TCP？还是...”
    ```

  - 引入这个结构体，可以用来表示不同的modbus总线，  
  - modbus_backend_t 结构体
  - 里面必定含有硬件相关的结构体 modbus_backend_t，谁让通信协议都得建立上硬件之上呢，就是所谓的后端

    ```c
    typedef struct _modbus_backend {
    unsigned int backend_type;
    unsigned int header_length;
    unsigned int checksum_length;
    unsigned int max_adu_length;
    int (*set_slave)(modbus_t *ctx, int slave);
    int (*build_request_basis)(
        modbus_t *ctx, int function, int addr, int nb, uint8_t *req);
    int (*build_response_basis)(sft_t *sft, uint8_t *rsp);
    int (*prepare_response_tid)(const uint8_t *req, int *req_length);
    int (*send_msg_pre)(uint8_t *req, int req_length);
    ssize_t (*send)(modbus_t *ctx, const uint8_t *req, int req_length);
    int (*receive)(modbus_t *ctx, uint8_t *req);
    ssize_t (*recv)(modbus_t *ctx, uint8_t *rsp, int rsp_length);
    int (*check_integrity)(modbus_t *ctx, uint8_t *msg, const int msg_length);
    int (*pre_check_confirmation)(modbus_t *ctx,
                                const uint8_t *req,
                                const uint8_t *rsp,
                                int rsp_length);
    int (*connect)(modbus_t *ctx);
    unsigned int (*is_connected)(modbus_t *ctx);
    void (*close)(modbus_t *ctx);
    int (*flush)(modbus_t *ctx);
    int (*select)(modbus_t *ctx, fd_set *rset, struct timeval *tv, int msg_length);
    void (*free)(modbus_t *ctx);
    } modbus_backend_t;
    ```

2，核心函数

```c
/* modbus_client */
modbus_t *ctx = NULL;       // 硬件框架的软件描述

Omitted code...
switch (use_backend) {      // 分支判断
        Omitted code...
        case RTU:
            ip_or_device = "/dev/ttyUSB1";      // 要打开哪一个串口（这得看`物理载体`是什么了）
        Omitted code...
        }
    Omitted code...
    else {
        ctx = modbus_new_rtu(ip_or_device, 115200, 'N', 8, 1);      // 设置哪些参数等等这些信息
    }

Omitted code...
if (use_backend == RTU) {
        modbus_set_slave(ctx, SERVER_ID);       // 要访问哪些设备
    }

Omitted code...
if (modbus_connect(ctx) == -1) {        // 打开串口，连接
    Omitted code...
}

Omitted code...
rc = modbus_write_bit(ctx, UT_BITS_ADDRESS, ON);    // 写线圈状态寄存器，写某一个位寄存器
                                                    // 内部包含：1.构造消息msg  2.发送send  3.等待回应recv
                                                    // 该函数的底层实现是  函数 write_single
    /* Jump to write_single Function... */
    Omitted code...
    req_length = ctx->backend->build_request_basis(ctx, function, addr, (int) value, req);      // 构建请求 build_request_basis
    rc = send_msg(ctx, req, req_length);                                                        // 发送消息 send_msg
    if (rc > 0) {
        Omitted code...
        rc = _modbus_receive_msg(ctx, rsp, MSG_CONFIRMATION);                                   // 接收回应 receive_msg
        rc = check_confirmation(ctx, req, rsp, rc);                                             // 检查回应 check_confirmation
    }


/* modbus_server */
Omitted code...
else {
        ctx = modbus_new_rtu(ip_or_device, 115200, 'N', 8, 1);      // 同上
        modbus_set_slave(ctx, SERVER_ID);                           // 同样从机也需要设置一遍，这样才知道主机的数据是不是给自己的
        Omitted code...
    }
rc = modbus_connect(ctx);       // 打开串口，连接
rc = modbus_receive(ctx, query);        // 接收主机的请求
rc = modbus_reply(ctx, query, rc, mb_mapping);  // 发送回应，或者如下：
modbus_reply_exception(ctx, query, MODBUS_EXCEPTION_SLAVE_OR_SERVER_BUSY);  // 发送原始的回应，主机收到后，可以进一步处理
```

3，libmodbus的层次

- app应用程序：main.c      （应用层）  Call the core function to implement it
- 接口函数：上述的核心函数  （核心层）  src\modbus.c
  - 抽象出的两个结构体
- 后端实现，两个结构体      （底层）    The final invocation
  - 实现数据的收发
