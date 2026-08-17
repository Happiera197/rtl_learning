# Ready/Valid Handshake Verification

这是一个使用 SystemVerilog 和 Verilator 编写的 Ready/Valid Handshake 学习项目。DUT 是一个 1-entry Ready/Valid Buffer，项目重点验证 handshake、backpressure、stall 稳定性和连续传输。

## Project Structure

```text
week5_ready_valid_handshake/
├── rtl/
│   └── rv_buffer_1entry.sv
├── tb/
│   ├── tb_rv_buffer_1entry.sv
│   └── rv_assertions.sv
├── Makefile
└── README.md
```

## Verification

Self-checking testbench 包含以下 directed tests：

- Reset
- Single transfer
- Backpressure
- Full buffer stall
- Stall recovery
- Continuous transfer

Queue scoreboard 根据输入和输出 handshake 检查数据是否丢失、重复、乱序或改变。

SystemVerilog Assertions 检查：

- stall 时 output valid 保持
- stall 时 output data 稳定
- reset 时 output valid 清零
- Source 被阻塞时 valid 和 data 保持

Cover properties 覆盖 input handshake、output handshake、backpressure、stall 后传输和连续传输。

## Run

```bash
make lint
```

```bash
make sim
```

```bash
make clean
```

## What I Learned

- 只有 `valid && ready` 才表示数据真正完成传输。
- Backpressure 会阻止满 buffer 接收新数据。
- Stall 期间 valid 和 data 必须保持稳定。
- SVA assertion 用于检查协议规则，cover property 用于确认场景是否发生。
- Self-checking testbench 可以通过 scoreboard 自动判断 PASS/FAIL。
- Makefile 可以统一管理 Verilator lint、simulation 和清理流程。
