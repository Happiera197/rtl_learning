# Week03 Day03 - FIFO Interface Testbench

## 项目简介

本项目在已有同步 FIFO 的基础上，对 testbench 结构进行重新组织，主要练习 SystemVerilog 中 `interface`、`clocking block` 和 `program` 的使用。

FIFO RTL 保持原有普通 module 端口不变，testbench 使用 `interface` 集中管理 FIFO 的读写及状态信号，并通过 `clocking block` 规定测试信号的驱动和采样时序。

测试程序使用 `program` 实现，并维护一个参考队列 `model_q` 与 DUT 的行为进行比较。

## 文件结构

```text
week3_fifo_interface/
├── rtl/
│   └── sync_fifo.sv
├── tb/
│   ├── fifo_if.sv
│   ├── fifo_test.sv
│   └── tb_top.sv
├── Makefile
└── README.md
```

- `sync_fifo.sv`：同步 FIFO RTL
- `fifo_if.sv`：定义 FIFO interface 和 clocking block
- `fifo_test.sv`：使用 program 编写自检测试
- `tb_top.sv`：产生时钟并连接 interface、DUT 和测试程序
- `Makefile`：完成 lint、仿真和波形查看

## 测试内容

Testbench 对 FIFO 的主要行为进行了检查，包括：

- 异步复位
- 单次及连续读写
- FIFO 数据顺序
- `empty`、`full`、`count` 状态
- 空 FIFO 读取
- 满 FIFO 写入
- 同时读写
- 读写指针回绕

测试中使用 SystemVerilog queue 建立参考 FIFO：

```systemverilog
data_t model_q[$];
```

DUT 成功写入时向参考队列尾部加入数据，成功读取时从队首取出期望数据，并与 DUT 的 `rdata` 进行比较。

## 学习收获

通过本项目，我进一步理解了 SystemVerilog 验证代码中不同结构的职责：

- `module` 用于描述实际硬件功能，FIFO RTL 仍保持独立的普通模块端口。
- `interface` 可以把一组相关信号集中管理，减少 testbench 中分散的信号声明和连接。
- `clocking block` 可以规定 testbench 相对于时钟沿的驱动和采样时机，避免直接在时钟沿附近随意操作信号。
- `program` 用于组织测试流程，将测试代码与 DUT 的硬件结构进一步分离。
- 理解了 `input #1step` 与 `output #0` 的基本时序含义，以及 clocking block 中的 `input/output` 是从 testbench 角度定义的。
- 学会使用 queue 建立简单的参考模型，并根据 DUT 的 `wrfire`、`rdfire` 规则预测实际读写行为。
- 进一步熟悉了参数化设计、`typedef`、`task`、`function` 和 `$sformatf` 等 SystemVerilog testbench 语法。
- 使用 Verilator 完成多文件工程的 lint、编译和仿真，并使用 GTKWave 查看波形。

## 使用方法

代码检查：

```bash
make lint
```

编译并运行仿真：

```bash
make sim
```

查看波形：

```bash
make wave
```

清理生成文件：

```bash
make clean
```
