# Week3 ALU Random Test

## 项目简介

本项目基于之前完成的参数化 ALU，使用 SystemVerilog 编写自检式 testbench，并通过 Verilator 完成 lint、编译和仿真。

testbench 包含少量定向测试和 5000 组随机测试，能够自动计算预期结果、比较 DUT 输出并统计错误数量。

## 文件结构

```text
week3_alu_random_test/
├── Makefile
├── README.md
├── rtl/
│   └── ALU.sv
└── tb/
    └── tb_alu_random.sv
```

## 使用方法

```bash
make lint
make sim
make sim SEED=12345
make clean
```

## 学习内容

通过本项目，主要学习了以下内容：

- 使用 `task` 封装重复的测试流程；
- 编写独立的 reference model，避免直接复制 DUT 的实现逻辑；
- 构建能够自动判断结果的自检式 testbench；
- 使用 `$urandom` 和 `$urandom_range` 生成随机输入；
- 使用随机种子复现相同的随机测试序列；
- 使用 `$value$plusargs` 从命令行读取仿真参数；
- 理解加法进位、减法借位和有符号溢出的区别；
- 区分有符号比较与无符号比较；
- 使用 `!==` 检查普通错误以及 `X`、`Z` 状态；
- 使用 `test_count` 和 `error_count` 统计测试结果；
- 使用 `$fatal` 在测试失败时返回错误状态；
- 使用 Makefile 管理 lint、编译、仿真和清理流程。

## 项目总结

本项目完成了从固定输入测试到随机自检测试的过渡。相比人工观察波形，自检式 testbench 能够自动运行大量测试并快速定位错误，为后续学习 FIFO、状态机及更复杂的验证方法打下基础。
