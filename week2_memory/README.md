# Week 2 Memory Practice

本项目使用 SystemVerilog 实现并验证三种 16×8 存储器：

- 16×8 ROM
- 异步读、同步写单端口 RAM
- 同步读、同步写单端口 RAM

## 目录结构

```text
week2_memory/
├── rtl/
│   ├── rom16x8.sv
│   ├── ram16x8_async_read.sv
│   └── ram16x8_sync_read.sv
├── tb/
│   └── tb_memory.sv
├── build/
├── Makefile
└── README.md
```

`build/` 用于保存 Verilator 生成的文件、仿真程序和 VCD 波形，不提交到 Git。

## 1. ROM

文件：

```text
rtl/rom16x8.sv
```

该模块实现一个 16×8 ROM：

- 16 个地址，地址范围为 0～15
- 每个地址保存 8 位数据
- 地址宽度为 4 位
- 只能读取，不能在运行过程中写入
- 采用异步读取

核心读取逻辑为：

```systemverilog
assign rdata = mem[addr];
```

当 `addr` 改变时，`rdata` 不需要等待时钟上升沿，会直接变为对应地址中的数据。

## 2. 异步读、同步写 RAM

文件：

```text
rtl/ram16x8_async_read.sv
```

该模块实现一个 16×8 单端口 RAM。

写入逻辑：

```systemverilog
always_ff @(posedge clk) begin
    if (we)
        mem[addr] <= wdata;
end
```

只有在以下两个条件同时满足时才会写入：

1. `clk` 出现上升沿
2. `we` 为 1

读取逻辑：

```systemverilog
assign rdata = mem[addr];
```

读取是异步的。只要 `addr` 改变，`rdata` 就会直接变为新地址中的数据，不需要等待时钟。

## 3. 同步读、同步写 RAM

文件：

```text
rtl/ram16x8_sync_read.sv
```

读写逻辑均位于时钟触发块中：

```systemverilog
always_ff @(posedge clk) begin
    if (we)
        mem[addr] <= wdata;

    rdata <= mem[addr];
end
```

写入必须等待时钟上升沿。

读取也必须等待时钟上升沿。即使 `addr` 已经改变，`rdata` 也不会立即变化，而是在下一个时钟上升沿后更新。

因此，在波形中可以看到：

- `async_rdata` 随地址立即变化
- `sync_rdata` 必须等待下一个时钟上升沿

## 4. 同地址同时读写

同步读 RAM 采用 read-first 行为。

假设某地址原来存储旧数据，同时在一个时钟上升沿对该地址进行读取和写入：

```systemverilog
mem[addr] <= wdata;
rdata     <= mem[addr];
```

由于使用非阻塞赋值，右侧表达式读取的是时钟上升沿到来前的旧值。

因此该时钟沿后：

- `mem[addr]` 被更新为新数据
- `rdata` 得到旧数据
- 新数据会在后续读取时钟沿被读出

对于异步读 RAM，写入完成后，组合读取端会直接显示新数据。

## 5. RAM 初始状态

两个 RAM 模块没有复位和初始化逻辑。

因此仿真开始时，尚未写入的存储地址可能显示未知值：

```text
xx
```

这是正常现象。Testbench 会先写入数据，再检查读取结果。

## 6. Testbench 验证内容

文件：

```text
tb/tb_memory.sv
```

Testbench 验证以下内容：

1. 检查 ROM 的全部 16 个地址
2. 向两种 RAM 写入相同的数据
3. 检查 `we=1` 时能够正确写入
4. 检查 `we=0` 时存储内容保持不变
5. 验证异步读在地址变化后立即更新
6. 验证同步读必须等待时钟上升沿
7. 验证同步 RAM 的 read-first 行为
8. 生成 `build/memory.vcd` 波形文件

## 7. 使用方法

进入项目目录：

```bash
cd ~/ai_for_ic/rtl_learning/week2_memory
```

运行 lint：

```bash
make lint
```

编译仿真程序：

```bash
make build
```

运行 testbench：

```bash
make run
```

打开已经生成的波形：

```bash
make wave
```

清除生成文件：

```bash
make clean
```

依次执行 lint、编译和仿真：

```bash
make
```

## 8. 波形观察重点

在 GTKWave 中展开：

```text
TOP
└── tb_memory
```

添加以下信号：

```text
clk
we
ram_addr
wdata
async_rdata
sync_rdata
```

重点观察：

1. 在两个时钟沿之间修改 `ram_addr`
2. `async_rdata` 会立即变化
3. `sync_rdata` 保持原值
4. 到下一个 `clk` 上升沿后，`sync_rdata` 才更新
5. 同地址读写时，同步 RAM 在当前拍输出旧数据
