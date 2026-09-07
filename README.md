 RTL Learning - AI for IC

本仓库记录本人在 AI for IC 方向上的学习过程，主要包括：

- 数字电路基础补充
- Verilog/SystemVerilog RTL设计
- 基于 Verilator 的仿真验证
- Testbench 编写
- SystemVerilog 验证方法与 UVM 入门学习

通过实践项目逐步建立从 **RTL设计 → 仿真验证 → 验证环境搭建** 的数字 IC 前端开发流程。

---

## 开发环境

- Language: SystemVerilog
- Simulator: Verilator
- Waveform Viewer: GTKWave
- IDE: VS Code + WSL
- Version Control: Git + GitHub

---

# Learning Progress

## Week 1: Verilog & Combinational Logic

学习内容：

- Verilog 基本语法
- Module结构
- 组合逻辑设计
- 参数化模块设计
- Testbench基础

实践项目：

### Parameterized ALU

完成一个参数化 ALU 模块设计：

支持：

- ADD
- SUB
- AND
- OR
- XOR
- SLT
- SLTU
- SHL
- SHR

验证：

- 编写自检 Testbench
- 建立参考模型
- 随机测试
- Verilator 仿真验证

---

## Week 2: Sequential Logic & Memory Design

学习内容：

- 时序逻辑设计
- 寄存器
- RAM/ROM建模
- 同步与异步读写区别

实践项目：

完成：

- ROM设计
- 异步读RAM
- 同步读RAM

并通过 Testbench 验证存储模块功能。

---

## Week 3: FIFO Design & Verification

学习内容：

- 状态控制
- 指针管理
- 边界条件处理
- 模块级验证方法

实践项目：

完成：

- Synchronous FIFO
- Ready/Valid Buffer

验证内容：

- Reset测试
- Empty/Full测试
- 连续读写测试
- 随机测试

---

## Week 4: Verification Improvement

学习内容：

- 自动化测试流程
- Reference Model
- Random Testing

实践内容：

- 完善 ALU/FIFO 测试环境
- 使用 Verilator 进行自动化仿真
- 提高测试覆盖范围

---

## Week 5-6: SystemVerilog Verification & UVM Introduction

学习内容：

SystemVerilog：

- class
- inheritance
- interface
- constraint randomization
- mailbox/semaphore

UVM：

- uvm_component体系
- test/env/agent结构
- driver
- monitor
- sequencer
- scoreboard
- phase机制

实践：

尝试将传统 Testbench 迁移至 UVM 验证框架，理解标准化验证环境的组织方式。

---

# Current Ability

目前已经能够：

- 独立完成简单 RTL 模块设计
- 编写自检 Testbench
- 使用 Verilator 完成 lint 与仿真验证
- 使用随机测试验证硬件模块
- 理解基础 SystemVerilog/UVM 验证架构

---

# Future Plan

后续计划继续学习：

- SystemVerilog Assertions (SVA)
- Functional Coverage
- Constraint Random Verification
- 完善 UVM 验证环境

并进一步学习：

- AXI接口设计
- RISC-V相关模块
- OpenTitan等开源项目

---

# Repository

GitHub:

https://github.com/Happiera197/rtl_learning
