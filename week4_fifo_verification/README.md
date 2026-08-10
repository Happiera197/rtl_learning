# Synchronous FIFO Verification

一个基于 **SystemVerilog + Verilator** 的同步 FIFO 自检验证项目。

项目通过 SystemVerilog `queue` 构建 Reference Model，自动比较 DUT 的数据和状态，并使用定向测试与随机测试验证 FIFO 的主要功能。

## 项目功能

- 使用 `queue` 构建 FIFO Reference Model
- 自动检查 `count`、`empty`、`full`
- 自动比较 FIFO 读出数据
- 验证 Reset、Full、Empty、同时读写等场景
- 使用 `fifo_transaction` 类描述 FIFO transaction
- 根据 FIFO 当前状态调整随机读写概率
- 主动覆盖 Full、Empty、同时读写和指针回绕
- 使用固定 Seed 实现可复现随机测试
- 使用 Makefile 管理 lint、单测试和 regression
- 自动输出 `PASS / FAIL`

随机测试示例结果：

```text
FIFO Verification Summary
Test   : random
Checks : 35607
Errors : 0
RESULT : PASS
```

## 项目结构

```text
week4_fifo_verification/
├── rtl/
│   └── sync_fifo.sv
├── tb/
│   ├── fifo_transaction.sv
│   ├── tb_sync_fifo.sv
│   └── tb_transaction.sv
├── Makefile
└── README.md
```

## 常用命令

```bash
make lint
make basic
make reset
make full_empty
make simultaneous_rw
make random SEED=12345
make regression
make clean
```

## 学习收获

- SystemVerilog `class`、object 和 transaction 的基本使用
- 使用 Reference Model 搭建 self-checking testbench
- Directed Test 与 Random Test 的区别和配合方式
- 使用 `$urandom_range` 生成随机 stimulus
- 根据 DUT 状态设计更有目的性的随机测试
- 使用 Seed 复现随机测试中发现的问题
- 理解 Full、Empty、同时读写和 pointer wraparound 等 FIFO 边界场景
- 使用 Verilator 和 Makefile 搭建完整的 lint、simulation 和 regression 流程

