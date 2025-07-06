# RTOS����

1��������ߵ�׼������Vscode�У�

- Cortex Debugger �����Զ���װ��������оͰ���RTOS View����������òμ���[text](<Vscode EIDE+Cortex Debug�STM32�������滷��.html>)
- EIDE��������òμ���[text](VSCode+EIDE����STM32.html)

2��settings.json �ļ���

- ע�ⲻ�� .vscode �ļ����µ�settings.json������ Cortex Debugger �����У�����~�б༭���򿪵�settings.json
- Ҫ��ӵ���Ҫ�ǣ�

```json
    "cortex-debug.armToolchainPath": "D:\\Program Files (x86)\\GNU Arm Embedded Toolchain\\10 2021.10\\bin",    // ARM Tool Chain �����������أ�Ҳ������eide����
    // "cortex-debug.armToolchainPath": "C:\\Users\\33362\\.eide\\tools\\gcc_arm\\bin",                         // ���eide���ص�Ҳ�ǿ��Ե�
    "cortex-debug.openocdPath": "C:\\Users\\33362\\.eide\\tools\\openocd_7a1adfbec_mingw32\\bin\\openocd.exe",  // ��eide���أ�Ĭ�ϴ���C/User/.eide/...��λ��

    - ARM Tool Chain����������ص�
```

3��launch.json �ļ���

- ��Ҫ��ӵ��ǣ�

```json
        {
            "cwd": "${workspaceRoot}",              // ·�������øĶ�
            "type": "cortex-debug",                 // �������ͣ����øĶ�
            "request": "launch",
            "name": "ST-Link",                      // ST-Link��������⣬����Ӧ������ѡ�Ծ���
            "servertype": "openocd",                // GDB-Server�������������
            "executable": "D:\\TEXT_EIDE\\Projects\\MDK-ARM\\build\\FreeRTOS\\atk_f407.elf",    //��Ҫ�޸ĳ����Լ��ļ�·�������ƣ����㲻��·��ʹ�þ���·��Ҳ����
            "runToEntryPoint": "main",
            "configFiles": [
               "C:\\Users\\33362\\.eide\\tools\\openocd_7a1adfbec_mingw32\\share\\openocd\\scripts\\interface\\stlink-v2.cfg",  // �����������ļ�
               "C:\\Users\\33362\\.eide\\tools\\openocd_7a1adfbec_mingw32\\share\\openocd\\scripts\\target\\stm32f4x.cfg"       // Ŀ�������ļ�
            ]
        }
    - .elf �ļ��� ELF��Executable and Linkable Format����ִ��������Ӹ�ʽ�� ��׼���ļ�����Ƕ��ʽ������ Linux �����к��ĵĳ�������
    - �����������ļ��ڣ�C:\Users\33362\.eide\tools\openocd_7a1adfbec_mingw32\share\openocd\scripts\interface
    - Ŀ�������ļ��ڣ�C:\Users\33362\.eide\tools\openocd_7a1adfbec_mingw32\share\openocd\scripts\target
```

4��Ϊ��������ã�Ϊʲô�Ƿ������������OpenOCD��

- ![alt text](Cortex_Debugger����-1.png)
- gdb��һ��PC���򣬴˴���ָ arm-none-eabi-gdb.exe����ARM-GNU�ṩ
- GDB Server��һ��PC������ gdb���� �� Ӳ�������� ֮�乵ͨ�����������ڽ�������gdb�������Ӳ���ĵ�������
  - ������GDB Server�����У�OpenOCD��JLinkGDBServer.exe��pyOCD
- Ӳ����������һ��Ӳ���豸��Ҳ�С�Ӳ�����������������ǽ��յ���������ֱ�ӿ���оƬ�������ص�������
  - �����ϳ�����Ӳ����������JLink��STLink��CMSIS-DAP��JLink-OB
- <https://discuss.em-ide.com/blog/67-cortex-debug>���������launch.json�����Խ��ܵĺ���ϸ

5��GDB��GNU Debugger
