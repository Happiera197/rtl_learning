# Week 2：同步 FIFO 与 Ready-Valid Buffer

本项目实现了两个常用的同步数据缓冲模块：

1. 参数化同步 FIFO（`sync_fifo`）
2. 单项 Ready-Valid 缓冲器（`rv_buffer_1entry`）

两个模块均使用 SystemVerilog 编写，并配套自检 Testbench。测试覆盖空读、满写、指针回绕、同时读写、反压保持、中途复位和随机数据传输等情况。

---

## 目录结构

```text
week2_fifo/
├── Makefile
├── rtl/
│   ├── sync_fifo.sv
│   └── rv_buffer_1entry.sv
└── tb/
    ├── tb_sync_fifo.sv
    └── tb_rv_buffer_1entry.sv
```

---

# 1. 同步 FIFO

文件：

```text
rtl/sync_fifo.sv
```

## 1.1 功能

`sync_fifo` 是一个参数化同步 FIFO，读写操作使用同一个时钟。

FIFO 采用以下结构：

- `mem`：保存数据
- `wrptr`：指向下一次写入地址
- `rdptr`：指向下一次读取地址
- `count`：记录当前有效数据数量
- `full`：FIFO 已满
- `empty`：FIFO 为空

FIFO 遵循先进先出原则：

```text
First In, First Out
```

先写入的数据一定先被读取。

## 1.2 参数

| 参数 | 默认值 | 说明 |
|---|---:|---|
| `DATA_WIDTH` | 8 | 每个数据的位宽 |
| `DATA_DEPTH` | 16 | FIFO 可以保存的数据个数 |

例如：

```systemverilog
sync_fifo #(
    .DATA_WIDTH(32),
    .DATA_DEPTH(8)
) dut (
    // ...
);
```

表示实例化一个深度为 8、数据宽度为 32 位的 FIFO。

## 1.3 接口

| 信号 | 方向 | 说明 |
|---|---|---|
| `clk` | input | 时钟 |
| `resetn` | input | 低电平有效异步复位 |
| `wren` | input | 写请求 |
| `wdata` | input | 写入数据 |
| `rden` | input | 读请求 |
| `rdata` | output | 读出数据 |
| `empty` | output | FIFO 为空 |
| `full` | output | FIFO 已满 |
| `count` | output | 当前有效数据数量 |

## 1.4 有效读写条件

外部的 `wren` 和 `rden` 只是请求，真正执行的操作由 `wrfire` 和 `rdfire` 表示。

```systemverilog
assign rdfire = rden && !empty;
assign wrfire = wren && (!full || rdfire);
```

### 读取

只有同时满足以下条件时才真正读取：

```text
rden = 1
empty = 0
```

即：

```systemverilog
rdfire = 1;
```

### 写入

以下两种情况可以写入：

1. FIFO 当前未满
2. FIFO 当前已满，但本周期同时成功读取

第二种情况下，读操作腾出了一个位置，因此仍然允许写入。

## 1.5 `count` 更新规则

| `wrfire` | `rdfire` | 操作 | `count` 变化 |
|---:|---:|---|---|
| 0 | 0 | 无有效读写 | 不变 |
| 0 | 1 | 只读 | 减 1 |
| 1 | 0 | 只写 | 加 1 |
| 1 | 1 | 同时读写 | 不变 |

虽然同时读写时 `count` 不变，但读写指针和存储内容都会更新。

## 1.6 指针回绕

当读写指针到达最后一个合法地址时，下次操作回到地址 0。

```text
0 → 1 → 2 → ... → DATA_DEPTH-1 → 0
```

代码显式判断最后地址，因此也支持深度不是 2 的整数次幂的情况。

## 1.7 空满保护

### 空读保护

FIFO 为空时，即使 `rden = 1`，也不会移动读指针或减少 `count`。

### 满写保护

FIFO 已满且没有同时读取时，即使 `wren = 1`，也不会覆盖尚未读取的数据。

---

# 2. Ready-Valid 单项缓冲器

文件：

```text
rtl/rv_buffer_1entry.sv
```

## 2.1 功能

`rv_buffer_1entry` 是一个只能保存一个数据的 Ready-Valid 缓冲器。

接口分为上下游两侧：

```text
上游                         下游

i_valid ───────▶
i_data  ───────▶   Buffer   ───────▶ o_valid
        ◀─────── o_ready    ───────▶ o_data
                             ◀─────── i_ready
```

## 2.2 握手规则

输入端握手：

```systemverilog
input_fire = i_valid && o_ready;
```

输出端握手：

```systemverilog
output_fire = o_valid && i_ready;
```

只有 `valid && ready` 同时为 1 时，数据才真正完成传输。

## 2.3 `o_ready` 逻辑

```systemverilog
assign o_ready = !o_valid || i_ready;
```

缓冲器在以下两种情况下可以接收新数据：

1. 当前为空，即 `o_valid = 0`
2. 当前有数据，但下游本周期会接收旧数据，即 `i_ready = 1`

这使缓冲器可以在同一个时钟周期中完成：

```text
旧数据输出
+
新数据输入
```

从而达到每周期传输一个数据的吞吐率。

## 2.4 状态变化

| `input_fire` | `output_fire` | 操作 | 新状态 |
|---:|---:|---|---|
| 0 | 0 | 无传输 | 保持 |
| 0 | 1 | 旧数据被取走 | 变空 |
| 1 | 0 | 接收新数据 | 变满 |
| 1 | 1 | 旧数据输出，新数据输入 | 保持满 |

## 2.5 反压

当：

```text
o_valid = 1
i_ready = 0
```

表示缓冲器中已有数据，但下游暂时不能接收。

此时：

```text
o_ready = 0
```

缓冲器会阻止上游继续发送，并保持：

```text
o_valid 不变
o_data 不变
```

这种由下游向上游传播的暂停机制称为：

```text
Backpressure
反压
```

---

# 3. Testbench

## 3.1 FIFO Testbench

文件：

```text
tb/tb_sync_fifo.sv
```

测试内容包括：

- 异步复位
- 空读保护
- 连续写入直到满
- 满写保护
- 满状态同时读写
- 顺序读取检查
- 空状态同时读写
- 指针回绕
- 随机读写测试
- 中途复位

Testbench 使用独立参考模型检查：

- 数据是否丢失
- 数据是否重复
- 数据顺序是否正确
- `count` 是否正确
- `full` 和 `empty` 是否正确

仿真通过时输出：

```text
PASS: tb_sync_fifo
```

## 3.2 Ready-Valid Buffer Testbench

文件：

```text
tb/tb_rv_buffer_1entry.sv
```

测试内容包括：

- 异步复位
- 空缓冲器接收数据
- 下游阻塞时保持数据
- 数据正常输出
- 同周期输出旧数据并接收新数据
- 连续吞吐
- 随机握手测试
- 中途复位

仿真通过时输出：

```text
PASS: tb_rv_buffer_1entry
```

---

# 4. 仿真环境

本项目使用：

- SystemVerilog
- Verilator
- Make
- GTKWave

检查 Verilator 是否安装：

```bash
verilator --version
```

---

# 5. 运行方法

进入项目目录：

```bash
cd ~/ai_for_ic/rtl_learning/week2_fifo
```

## 5.1 清理生成文件

```bash
make clean
```

## 5.2 Lint

```bash
make lint
```

## 5.3 运行全部仿真

```bash
make sim
```

建议使用：

```bash
make clean && make lint && make sim
```

这样只有上一条命令成功后，下一条命令才会执行。

## 5.4 单独运行 FIFO

```bash
make sim_fifo
```

## 5.5 单独运行 Ready-Valid Buffer

```bash
make sim_rv
```

---

# 6. 仿真结果

正确运行后，应看到：

```text
PASS: tb_sync_fifo
PASS: tb_rv_buffer_1entry
```

当前测试已覆盖定向测试和随机回归测试，两个模块均通过功能仿真。

---

# 7. 查看波形

仿真会生成：

```text
sync_fifo.vcd
rv_buffer_1entry.vcd
```

查看 FIFO 波形：

```bash
gtkwave sync_fifo.vcd
```

查看 Ready-Valid Buffer 波形：

```bash
gtkwave rv_buffer_1entry.vcd
```

FIFO 建议观察：

```text
clk
resetn
wren
wdata
rden
rdata
wrfire
rdfire
wrptr
rdptr
count
full
empty
```

Ready-Valid Buffer 建议观察：

```text
clk
resetn
i_valid
o_ready
i_data
o_valid
i_ready
o_data
input_fire
output_fire
```

---

# 8. 关键学习内容

通过本项目可以掌握：

- 同步 FIFO 的基本结构
- 存储数组与读写指针
- FIFO 空满判断
- 指针循环回绕
- 同周期读写
- 参数化 RTL 设计
- Ready-Valid 握手
- Backpressure 反压
- `valid && ready` 传输条件
- 阻塞期间保持 `valid` 和 `data`
- 自检 Testbench
- 参考模型
- 定向测试与随机测试
- Verilator 仿真流程

---

# 9. Git 提交

在仓库根目录执行：

```bash
cd ~/ai_for_ic/rtl_learning

git add week2_fifo .gitignore

git commit -m "week02: implement synchronous FIFO and ready-valid buffer"

git push origin main
```

建议不要提交以下生成文件：

```text
obj_dir/
obj_dir_*/
*.vcd
*.fst
core
core.*
```
