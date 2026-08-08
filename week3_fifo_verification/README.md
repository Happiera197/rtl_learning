# Synchronous FIFO Verification

一个基于 **SystemVerilog + Verilator** 的同步 FIFO 自检验证项目。

本项目在已有 `sync_fifo` RTL 的基础上，搭建了一个不依赖人工查看波形的 self-checking testbench，通过参考模型、定向测试和随机测试自动判断 FIFO 功能是否正确，并使用 Makefile 管理 lint、编译、单测试运行和回归测试流程。

## 项目功能

验证环境主要包含：

* 使用 SystemVerilog `queue` 构建 FIFO Reference Model
* 自动检查 `count`、`empty`、`full`
* 自动比较 FIFO 读出数据与参考模型
* 针对关键场景编写 Directed Tests
* 进行 10000 周期随机读写测试
* 自动统计检查次数和错误数量
* 支持选择单个 testcase 运行
* 支持一键运行完整 Regression
* 支持按需生成 FST 波形
* 最终自动输出 `PASS / FAIL`

目前覆盖的主要测试场景：

* Reset
* Empty Read
* Full Write
* Consecutive Read & Write
* Simultaneous Read & Write
* Pointer Wrap Around
* Mid-test Reset
* Random Read/Write Regression

## 仿真结果

当前 `basic` testcase 已通过实际仿真：

```text
========================================
FIFO Verification Summary
Test   : basic
Checks : 37
Errors : 0
RESULT : PASS
========================================
```

该测试覆盖基本读写、FIFO 数据顺序以及读写指针回绕，并由 Reference Model 自动完成结果检查。

其余 testcase 可通过 `make regress` 统一运行，并将各测试的详细输出保存到 `logs/` 目录。

完整 FIFO Regression 已通过实际仿真，所有 testcase 均测试通过：

```text
========================================
FIFO Regression
========================================
basic              : PASS
reset              : PASS
full_empty         : PASS
simultaneous_rw    : PASS
random             : PASS
----------------------------------------
Passed : 5
Failed : 0
RESULT : PASS
========================================

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
├── README.md
└── .gitignore
```

## 运行方法

需要安装：

* Verilator
* GNU Make
* GTKWave（查看波形时需要）

Lint：

```bash
make lint
```

编译：

```bash
make build
```

运行单个测试：

```bash
make sim TEST=basic
make sim TEST=reset
make sim TEST=full_empty
make sim TEST=simultaneous_rw
make sim TEST=random
```

不指定 `TEST` 时默认运行 `basic`：

```bash
make sim
```

运行完整回归：

```bash
make regress
```

查看指定测试的波形：

```bash
make wave TEST=basic
```

清理生成文件：

```bash
make clean
```

## 学习收获

* 理解 **Specification → Testplan → Test → Checker** 的基本验证流程
* 学会根据功能规格设计测试点，而不是只进行简单输入输出测试
* 使用 SystemVerilog `queue` 搭建 Reference Model
* 理解 Reference Model 应独立于 DUT，根据正确规格产生期望结果
* 理解一次请求和一次真正发生的 transaction 的区别
* 学会处理 FIFO 的 empty、full、同时读写和指针回绕等边界情况
* 理解 testbench 中时钟沿、非阻塞赋值和仿真调度带来的时序问题
* 编写能够自动发现错误的 self-checking testbench
* 使用随机测试进行较长周期的回归验证
* 使用 Verilator 完成 lint、编译和自动仿真
* 使用 Makefile 管理 build、单测试运行、波形查看和 Regression 流程
