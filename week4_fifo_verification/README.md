# FIFO Class-Based Verification

一个基于 **SystemVerilog + Verilator** 的同步 FIFO Class-Based 验证项目。

## 验证架构

```text
Generator → Driver → DUT → Monitor → Scoreboard
```

- **Transaction**：描述一次 FIFO 读写操作
- **Generator**：随机生成 transaction
- **Driver**：通过 virtual interface 驱动 DUT
- **Monitor**：采集 DUT 接口信号
- **Scoreboard**：比较 DUT 行为与参考结果
- **Mailbox / Event**：实现各验证组件之间的通信与同步

## 项目功能

- 使用 SystemVerilog class 搭建验证环境
- 使用 `randomize()` 产生随机激励
- 使用参数化 `mailbox` 传递 transaction
- 使用 `event` 同步 Generator 与 Driver
- 使用 `virtual interface` 连接 class 与 DUT
- Monitor 自动采集 FIFO 运行状态
- Scoreboard 自动进行结果检查
- 支持 Verilator lint 与仿真

## 仿真结果

仿真时 Generator 产生随机 transaction，经 Driver 驱动 FIFO，Monitor 采集实际行为并发送给 Scoreboard 检查。

示例输出：

```text
[GEN] write=1 read=0 data=0x35
[DRV] write=1 read=0 data=0x35
[MON] write=1 read=0 data=0x35
[SCB] PASS

========================================
FIFO Verification Summary
Transactions : 100
Errors       : 0
RESULT       : PASS
========================================
```

> 上述为 README 展示格式，最终结果以实际仿真输出为准。

## 学习收获

- class 与 object 的使用
- transaction 的设计方法
- Generator / Driver / Monitor / Scoreboard 的职责划分
- mailbox 的生产者—消费者通信方式
- event 的同步机制
- interface 与 virtual interface 的作用
- 随机测试和 self-checking verification 的基本思想
- 使用 Verilator 对 SystemVerilog 验证代码进行 lint 和仿真
