# Counter Self-Checking Testbench

## 项目简介

本项目实现了一个参数化向上计数器，并为其编写了自检式 Testbench。

计数器支持：

- 参数化位宽 `WIDTH`
- 低电平异步复位 `resetn`
- 计数使能 `en`
- 达到最大值后自动回绕到 0

Testbench 会自动产生时钟、施加测试激励、计算期望结果并检查 DUT 输出。测试失败时打印错误信息并终止仿真，全部通过时打印 `PASS`。

## 文件结构

```text
week3_counter_tb/
├── rtl/counter.sv
├── tb/tb_counter.sv
├── Makefile
└── README.md
```

## 测试内容

Testbench 依次检查：

- 复位时 `count` 是否清零
- `en=0` 时是否保持
- `en=1` 时是否连续加 1
- 最大值后是否回绕到 0
- 回绕后是否继续正常计数

## 学习内容

### 参数化设计

使用：

```systemverilog
parameter int unsigned WIDTH = 4
```

可以通过修改参数改变计数器位宽，提高模块复用性。

### 时序逻辑

计数器使用：

```systemverilog
always_ff @(posedge clk or negedge resetn)
```

表示正常计数发生在时钟上升沿，复位信号下降时立即清零。时序逻辑中的寄存器更新使用非阻塞赋值 `<=`。

### Testbench 时钟

```systemverilog
always #(CLK_PERIOD / 2) clk = ~clk;
```

每隔半个周期翻转一次时钟。`#` 延时只用于仿真，不能综合。

### task 封装

`task automatic apply_and_check` 将一轮测试封装为：

1. 在下降沿设置输入
2. 等待上升沿让 DUT 更新
3. 计算期望值
4. 比较实际值和期望值

这样可以减少重复代码。

### 避免竞争

DUT 在上升沿采样，因此 Testbench 在下降沿改变输入，避免两者在同一边沿同时读写信号产生 race。

上升沿后等待 `#1ps`，是为了确保 DUT 的非阻塞赋值已经完成。

### 自动检查

`expected` 保存参考结果，使用：

```systemverilog
if (count !== expected)
```

检查 DUT 输出。`!==` 还能识别 `x` 和 `z` 状态。

测试失败使用 `$fatal`，全部通过使用 `$display` 输出 `PASS`，因此无需人工查看波形。

## 仿真命令

```bash
make lint
make sim
make clean
```

全部通过时应看到：

```text
PASS: all 37 checked cycles passed.
```
