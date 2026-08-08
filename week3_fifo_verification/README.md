# Synchronous FIFO Verification

一个基于 **SystemVerilog + Verilator** 的同步 FIFO 自检验证项目。

本项目在已有 `sync_fifo` RTL 的基础上，搭建了一个不依赖人工查看波形的 self-checking testbench，通过参考模型、定向测试和随机测试自动判断 FIFO 功能是否正确。

## 项目功能

验证环境主要包含：

- 使用 SystemVerilog `queue` 构建 FIFO Reference Model
- 自动检查 `count`、`empty`、`full`
- 自动比较 FIFO 读出数据与参考模型
- 针对关键场景编写 Directed Tests
- 进行 10000 周期随机读写测试
- 自动统计检查次数和错误数量
- 最终自动输出 `PASS / FAIL`

目前覆盖的主要测试场景：

- Reset
- Empty Read
- Full Write
- Consecutive Read & Write
- Simultaneous Read & Write
- Pointer Wrap Around
- Mid-test Reset
- Random Read/Write Regression

一次 10000 周期随机回归结果示例：

```text
==============================
FIFO Verification Summary
Checks : 34949
Errors : 0
RESULT : PASS
==============================
```

## 项目结构

```text
week3_fifo_verification/
├── rtl/
│   └── sync_fifo.sv
├── tb/
│   └── tb_sync_fifo.sv
├── docs/
│   └── testplan.md
├── Makefile
└── README.md
```

## 运行方法

需要安装 Verilator。

```bash
make lint
make sim
```

也可以直接运行：

```bash
make
```

清理生成文件：

```bash
make clean
```

## 学习收获

- 理解 **Specification → Testplan → Test → Checker** 的基本验证流程
- 学会根据功能规格设计测试点，而不是只进行简单输入输出测试
- 使用 SystemVerilog `queue` 搭建 Reference Model
- 理解 Reference Model 应独立于 DUT，根据正确规格产生期望结果
- 理解一次请求和一次真正发生的 transaction 的区别
- 学会处理 FIFO 的 empty、full、同时读写和指针回绕等边界情况
- 理解 testbench 中时钟沿、非阻塞赋值和仿真调度带来的时序问题
- 编写能够自动发现错误的 self-checking testbench
- 使用随机测试进行较长周期的回归验证
- 使用 Verilator 完成 lint、编译和自动仿真

