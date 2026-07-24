# Week 1 Parameterized ALU

本项目使用 SystemVerilog 实现了一个参数化算术逻辑单元，并使用自检查 Testbench 对全部运算和标志位进行验证。

## 目录结构

```text
week1_summary_ALU/
├── rtl/
│   └── ALU.sv
├── tb/
│   └── tb_ALU.sv
├── build/
├── Makefile
└── README.md
```

其中：

- `rtl/` 保存可综合的 RTL 代码
- `tb/` 保存仿真 Testbench
- `build/` 保存 Verilator 生成文件和波形，不提交到 Git
- `Makefile` 用于执行 lint、编译、仿真和波形查看

## ALU 接口

ALU 支持参数化数据宽度，默认宽度为 8 位。

```systemverilog
module ALU #(
    parameter int unsigned WIDTH = 8
) (
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic [3:0]       op,

    output logic [WIDTH-1:0] result,
    output logic             zero,
    output logic             carry,
    output logic             overflow
);
```

## 运算编码

| 操作 | `op` | 功能 |
|---|---:|---|
| ADD | `4'h0` | `a + b` |
| SUB | `4'h1` | `a - b` |
| AND | `4'h2` | `a & b` |
| OR | `4'h3` | `a \| b` |
| XOR | `4'h4` | `a ^ b` |
| SLT | `4'h5` | 有符号小于比较 |
| SLTU | `4'h6` | 无符号小于比较 |
| SHL | `4'h7` | `a` 逻辑左移 1 位 |
| SHR | `4'h8` | `a` 逻辑右移 1 位 |

对于 `SLT` 和 `SLTU`：

- 条件成立时，`result` 为最低位等于 1、其余位为 0
- 条件不成立时，`result` 全部为 0

## 标志位定义

### zero

当运算结果全部为 0 时置 1：

```systemverilog
zero = (result == '0);
```

### carry

对于加法，`carry` 表示最高位产生的进位。

对于减法，电路通过：

```systemverilog
a + ~b + 1'b1
```

实现二进制补码减法。此时 `carry=1` 表示没有借位，`carry=0` 表示发生借位。

对于逻辑、比较和移位运算，`carry` 置 0。

### overflow

`overflow` 表示有符号加减法溢出。

加法溢出条件：

- 两个操作数符号相同
- 运算结果符号与操作数不同

减法溢出条件：

- 两个操作数符号不同
- 运算结果符号与被减数不同

对于其他操作，`overflow` 置 0。

## Testbench

`tb/tb_ALU.sv` 是一个自检查 Testbench。

它会自动：

1. 执行边界和定向测试
2. 检查加法进位
3. 检查加法和减法的有符号溢出
4. 检查减法借位行为
5. 分别验证有符号和无符号比较
6. 验证逻辑运算和移位运算
7. 对每种操作执行 200 组随机测试
8. 比较 `result`、`zero`、`carry` 和 `overflow`
9. 在错误时输出输入、操作码、预期值和实际值
10. 全部测试通过后输出 PASS 信息

9 种操作共执行至少 1800 组随机测试，此外还包括定向边界测试。

## 使用方法

进入项目目录：

```bash
cd ~/ai_for_ic/rtl_learning/week1_summary_ALU
```

运行 lint：

```bash
make lint
```

编译仿真程序：

```bash
make build
```

运行 Testbench：

```bash
make run
```

打开波形：

```bash
make wave
```

清除自动生成文件：

```bash
make clean
```

依次执行 lint、编译和仿真：

```bash
make
```

## 波形观察

在 GTKWave 中可以重点观察：

```text
a
b
op
result
zero
carry
overflow
```

Testbench 以自动检查为主要验证手段，波形用于辅助分析失败用例，而不是依赖人工观察判断正确性。

## 工具

本项目使用：

- SystemVerilog
- Verilator
- GTKWave
- GNU Make
- Git
