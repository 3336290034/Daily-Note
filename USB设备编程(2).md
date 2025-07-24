# USB设备编程------内容补充

1，Pipe：usb通信的最基本形式是通过USB设备里面的endpoint，而主机和endpoint之间的数据传输就是通过pipe

- pipe中数据通信方式有两种，一种是`stream`一种是`message`。message要求进出进出方向必须要求同一个管道，默认就使用ep0作为message管道
2，Endpoint：端点是有方向的，主机到从机的是out端点，从机到主机的是in端点
