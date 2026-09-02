# UVM FIFO Verification

## 项目简介

这是一个同步 FIFO 的 SystemVerilog/UVM 验证学习项目。

RTL 是参数化 synchronous FIFO，当前参数为：

```text
DATA_WIDTH = 8
DATA_DEPTH = 16
```

UVM 验证环境目前实现了：

- `fifo_item` transaction
- `fifo_sequence`
- `fifo_sequencer`
- `fifo_driver`
- `fifo_monitor`
- `fifo_agent`
- `fifo_scoreboard`
- `fifo_env`
- `fifo_test`
- virtual interface
- `uvm_config_db`
- reference queue model
- 自动 PASS/FAIL 检查

目前 functional coverage 还没有正式实现。

## 验证结构

```text
fifo_test
   |
fifo_env
   |
fifo_agent
   |
   +-- fifo_sequencer --> fifo_driver --> fifo_if --> DUT
   |
   +-- fifo_monitor --> fifo_scoreboard
```

数据流可以简单表示为：

```text
sequence
   ↓
sequencer
   ↓
driver
   ↓
fifo_if
   ↓
sync_fifo
   ↓
monitor
   ↓
scoreboard
```

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
    ├── fifo_env.sv
    ├── fifo_test.sv
    ├── fifo_pkg.sv
    └── tb_top.sv
```

## 使用方法

编译项目：

```bash
make
```

编译并运行：

```bash
make run
```

也可以直接执行测试：

```bash
make test
```

清理编译生成的 `obj_dir`：

```bash
make clean
```

Makefile 默认使用下面的 UVM 路径：

```text
UVM_HOME=/home/happier/uvm-core/src
```

如果其他电脑上的 UVM 路径不同，可以在命令行中指定：

```bash
make UVM_HOME=/path/to/uvm/src
```

## 当前验证内容

当前 sequence 主要进行 constrained-random FIFO 操作，包括：

- `READ`
- `WRITE`
- `WRITE_READ`
- `RESET`

Scoreboard 使用 SystemVerilog queue 作为 reference model，并检查：

- FIFO 读数据
- `count`
- `empty`
- `full`
- reset 状态

## 学习内容

通过这个项目主要学习：

1. UVM 的基本组件层次：test / env / agent / sequencer / driver / monitor / scoreboard。
2. sequence、sequencer 和 driver 之间的数据传递关系。
3. 使用 virtual interface 让 UVM class 操作 DUT 信号。
4. 使用 `uvm_config_db` 将 interface 从 `tb_top` 传递给 driver 和 monitor。
5. 使用 `analysis_port` / `analysis_imp` 将 monitor transaction 发送给 scoreboard。
6. 使用 queue 建立简单的 FIFO reference model。
7. 使用 objection 控制 UVM `run_phase` 的开始和结束。
8. 理解 UVM 的 `build_phase`、`connect_phase`、`run_phase`、`report_phase` 的基本作用。
9. 使用 Verilator 编译和运行简单 UVM 工程。

## 后续计划

- 增加 reset、full、empty、wrap-around 等定向 sequence
- 增加 functional coverage
- 增加 assertion
- 增加更多 corner case
