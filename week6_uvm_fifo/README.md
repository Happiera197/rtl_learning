# UVM FIFO Verification

## 项目简介

这是一个基于 SystemVerilog 和 UVM 的同步 FIFO 验证学习项目。

RTL 是参数化 synchronous FIFO，当前参数为：

- `DATA_WIDTH = 8`
- `DATA_DEPTH = 16`

验证环境目前包含 transaction、sequence、sequencer、driver、monitor、agent、scoreboard、coverage collector 和 virtual interface，并使用 `uvm_config_db` 传递 interface、使用 `analysis_port` / `analysis_imp` 传递 transaction。

## UVM 架构

```text
fifo_test
    ↓
fifo_env
    ↓
fifo_agent

sequence ──→ sequencer ──→ driver ──→ fifo_if ──→ sync_fifo
                                      |
                                   monitor
                                      |
                               analysis_port
                                /          \
                               ↓            ↓
                         scoreboard      coverage
```

- driver 负责将 sequence item 转换为 DUT 信号。
- monitor 负责采集 DUT 行为并生成 transaction。
- scoreboard 使用 reference queue model 进行功能比较。
- coverage 负责统计 operation、FIFO 状态和交叉覆盖情况。

monitor 的 `analysis_port` 会将同一个 transaction 同时广播给 scoreboard 和 coverage collector。

## Coverage

### Code Coverage

Code Coverage 由 Verilator 自动生成，包括：

- line coverage
- toggle coverage

### Functional Coverage

Functional Coverage 在 `tb/fifo_coverage.sv` 中实现，使用：

- `covergroup`
- `coverpoint`
- `cross`

当前主要统计：

- `IDLE`、`READ`、`WRITE`、`WRITE_READ`、`RESET`
- FIFO 的 empty、middle、full count 状态
- `full` 和 `empty` 状态
- operation 与 FIFO count 状态的交叉覆盖

### Assertion Coverage

Assertion Coverage 通过 SVA `cover property` 统计：

- empty read
- full write
- simultaneous read/write

## Assertion

SVA 位于 `tb/fifo_if.sv`。interface 位于 DUT 与 testbench 的边界，可以直接观察 FIFO 控制信号和状态信号。

当前 assertion 主要检查：

- `count` 不超过 FIFO depth
- `empty` 与 `count == 0` 一致
- `full` 与 `count == DATA_DEPTH` 一致
- empty 状态下只读时 `count` 保持
- full 状态下只写时 `count` 保持
- simultaneous read/write 时 `count` 保持

## 目录结构

```text
week6_uvm_fifo/
├── Makefile
├── README.md
├── rtl/
│   └── sync_fifo.sv
└── tb/
    ├── fifo_if.sv
    ├── fifo_item.sv
    ├── fifo_sequence.sv
    ├── fifo_sequencer.sv
    ├── fifo_driver.sv
    ├── fifo_monitor.sv
    ├── fifo_agent.sv
    ├── fifo_scoreboard.sv
    ├── fifo_coverage.sv
    ├── fifo_env.sv
    ├── fifo_test.sv
    ├── fifo_pkg.sv
    └── tb_top.sv
```

`fifo_item.sv`、driver、monitor 等 UVM class 文件由 `fifo_pkg.sv` 使用 `` `include `` 包含，因此 Makefile 不会再次将它们单独加入编译文件列表。

## 使用方法

普通编译：

```bash
make
```

编译并运行：

```bash
make run
```

执行测试：

```bash
make test
```

编译 coverage 版本、运行仿真并生成 `coverage/coverage.dat`：

```bash
make coverage
```

生成 `coverage/summary.txt` 和带标注的 `coverage/annotated/`：

```bash
make coverage_report
```

删除 `obj_dir` 和 coverage 生成文件：

```bash
make clean
```

默认 UVM 路径为：

```text
UVM_HOME=/home/happier/uvm-core/src
```

如果其他电脑的 UVM 路径不同，可以指定：

```bash
make UVM_HOME=/your/path
```

## 当前验证内容

当前 sequence 主要进行 `READ`、`WRITE`、`WRITE_READ` 和 `RESET` constrained-random 操作。

Scoreboard 使用 SystemVerilog queue 作为 reference model，并检查 FIFO 读数据、`count`、`empty`、`full` 和 reset 状态。测试结束时会自动报告 PASS 或 FAIL。

## 学习收获

通过这个项目主要学习：

1. UVM test / env / agent 的分层结构。
2. sequence、sequencer 和 driver 之间的数据流。
3. monitor `analysis_port` 的广播机制。
4. scoreboard reference model 的基本实现。
5. 使用 covergroup 完成 functional coverage。
6. 使用 SVA assertion 检查时序行为。
7. code coverage 与 functional coverage 的区别。
8. Verilator + UVM + coverage 的基本工作流程。

## 后续计划

- 增加更多 directed sequence
- 提高 FIFO corner case coverage
- 完善 assertion
- 增加随机约束测试
