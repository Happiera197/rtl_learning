# 4-bit Counter Concurrent Assertions

## 项目简介

这是一个使用 SystemVerilog、Verilator 和 SystemVerilog Assertions（SVA）完成的简单验证项目。RTL 实现了一个 4-bit synchronous counter，支持低有效同步复位、使能计数，以及从最大值 `15` 回绕到 `0`。

项目结构：

```text
week05_counter_assertion/
├── rtl/counter.sv
├── tb/tb_counter.sv
├── Makefile
└── README.md
```

## 验证内容

Testbench 在 `@(posedge clk)` 采样并检查三类 concurrent assertion：

- Reset assertion：采样到复位有效后，检查下一拍 `count` 为 `0`。
- Enable assertion：复位无效、`enable` 有效且 `count != 15` 时，检查下一拍为 `$past(count) + 1`。
- Wrap assertion：复位无效、`enable` 有效且 `count == 15` 时，检查下一拍回绕到 `0`。

对应的 `cover property` 会记录 reset、普通 enable 计数和 wrap 场景是否真实发生。Testbench 结束前还会检查三个 cover 标志，避免 assertion 因触发条件从未出现而 vacuous pass。

最近一次正常仿真中，`c_reset`、`c_enable` 和 `c_wrap` 分别命中 2、17 和 1 次，仿真在 215 ns 正常结束。



## 运行方式

```bash
make lint
make build
make sim
```

正常仿真输出：

```text
PASS: reset, enable/increment, and wrap scenarios passed.
```

清理生成文件：

```bash
make clean
```

## 学习收获

- 使用 `property ... endproperty` 定义并用 `assert property` 启用并发断言。
- 使用 `cover property` 确认目标测试场景确实发生。
- 理解 `@(posedge clk)` 表示 assertion 在时钟上升沿采样信号。
- 理解 `|=>` 用于描述跨时钟周期的 implication。
- 使用 `disable iff (!resetn)` 在复位期间禁用 enable 和 wrap 检查。
- 使用 `$past()` 取得上一采样周期的信号值。
- assertion 适合检查局部设计规则和时序关系；scoreboard 更适合比较完整的 expected/actual 结果序列。本项目只使用 assertion，没有引入 scoreboard。
- 通过临时将 RTL 的递增值从 `+1` 改为 `+2`，确认 enable assertion 能发现真实设计错误；最终 RTL 已恢复为正确的 `+1`。
