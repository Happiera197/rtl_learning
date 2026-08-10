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
```

## Coverage 验证

在功能回归测试基础上，项目进一步使用 Verilator Coverage 分析测试是否充分覆盖 RTL。

当前启用：

- Line Coverage：检查 RTL 代码是否被执行
- Toggle Coverage：检查信号 bit 是否发生有效翻转

Coverage 使用独立的 Verilator build，并对全部 testcase 重新运行：

```bash
make coverage
```

每个 testcase 会分别生成 Coverage 数据：

```text
coverage/data/basic.dat
coverage/data/reset.dat
coverage/data/full_empty.dat
coverage/data/simultaneous_rw.dat
coverage/data/random.dat
```

随后使用 `verilator_coverage` 合并为完整 Regression Coverage，并生成 summary 与 annotated source。

当前实际 Coverage 结果：

```text
Coverage Summary:
  line      : 100.0% (45/45)
  toggle    : 100.0% (384/384)
  branch    : 75.0%  (33/44)
  expr      : 0.0%   (0/0)
  fsm_state : 0.0%   (0/0)
  fsm_arc   : 0.0%   (0/0)
```

其中本项目重点关注的 **Line Coverage 与 Toggle Coverage 均达到 100%**。

进一步检查 annotated source 后，未覆盖的 branch 均出现在 testbench 中，没有发现 DUT `sync_fifo.sv` 中的未覆盖 Coverage Point。这些未覆盖项主要来自 checker 的错误处理、FAIL 分支等测试基础设施路径，因此不通过故意制造错误来追求无意义的 100% 总覆盖率。

Coverage 在本项目中的作用是发现测试遗漏，而不是判断 RTL 功能是否正确：

- Self-checking Testbench / Reference Model：判断结果是否正确
- Coverage：判断 RTL 是否得到了充分测试

因此，本项目采用“有意义的测试场景驱动 Coverage”的方式，而不是单纯延长随机仿真时间来提高覆盖率。

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

运行 Coverage Regression：

```bash
make coverage
```

运行后会自动完成：

```text
Coverage Build
    ↓
运行全部 Testcase
    ↓
生成各测试 Coverage 数据
    ↓
合并 Coverage
    ↓
生成 Coverage Summary
    ↓
生成 Annotated Source
```

主要结果位于：

```text
coverage/summary.txt
coverage/annotated/
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
* 理解 **功能正确性与 Code Coverage 的区别**
* 学会使用 Verilator 的 **Line Coverage 与 Toggle Coverage**
* 理解 Line Coverage 用于观察代码是否执行，Toggle Coverage 用于观察信号 bit 是否得到有效激励
* 学会为不同 testcase 分别收集 Coverage，并合并得到 Regression Coverage
* 学会通过 annotated source 定位未覆盖的代码路径和 Coverage Point
* 理解 Coverage 的目标不是机械追求 100%，而是发现真正的 Verification Hole
* 理解覆盖率提升应来自有意义的 Directed Test，而不是单纯延长随机测试时间
