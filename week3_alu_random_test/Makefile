TOP      := tb_alu_random
RTL      := rtl/ALU.sv
TB       := tb/tb_alu_random.sv

OBJ_DIR  := obj_dir
BIN      := $(OBJ_DIR)/V$(TOP)

SEED ?= 20260727

VERILATOR_FLAGS := \
	--binary \
	--timing \
	-j 0 \
	-Wall \
	-Wno-fatal \
	--top-module $(TOP) \
	--Mdir $(OBJ_DIR)


.PHONY: all sim lint clean

all: sim


# 编译并运行仿真
sim: $(BIN)
	./$(BIN) +SEED=$(SEED)


# 当 RTL 或 testbench 发生修改时，重新编译
$(BIN): $(RTL) $(TB)
	verilator $(VERILATOR_FLAGS) $(RTL) $(TB)


# 只进行语法和 lint 检查
lint:
	verilator \
		--lint-only \
		--timing \
		-Wall \
		-Wno-fatal \
		--top-module $(TOP) \
		$(RTL) $(TB)


# 删除 Verilator 生成的文件
clean:
	rm -rf $(OBJ_DIR)
