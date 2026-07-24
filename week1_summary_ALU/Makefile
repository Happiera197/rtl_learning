SHELL := /bin/bash
.RECIPEPREFIX := >

VERILATOR ?= verilator
GTKWAVE   ?= gtkwave

TOP       := tb_ALU
BUILD_DIR := build
OBJ_DIR   := $(BUILD_DIR)/obj_dir
SIM       := $(OBJ_DIR)/sim_alu
VCD       := $(BUILD_DIR)/alu.vcd

RTL_SRCS := rtl/ALU.sv
TB_SRCS  := tb/tb_ALU.sv
SOURCES  := $(RTL_SRCS) $(TB_SRCS)

COMMON_FLAGS := \
	--sv \
	--timing \
	-Wall \
	--Wno-fatal

.PHONY: all lint build run wave clean

all: lint run

lint:
>$(VERILATOR) \
>	$(COMMON_FLAGS) \
>	--lint-only \
>	--top-module $(TOP) \
>	$(SOURCES)

build:
>mkdir -p $(BUILD_DIR)
>rm -rf $(OBJ_DIR)
>$(VERILATOR) \
>	$(COMMON_FLAGS) \
>	--binary \
>	--trace \
>	--top-module $(TOP) \
>	--Mdir $(OBJ_DIR) \
>	-o sim_alu \
>	$(SOURCES)

run: build
>./$(SIM)

wave:
>test -f $(VCD) || { \
>	echo "Error: $(VCD) does not exist."; \
>	echo "Run 'make run' first and confirm that tb_ALU dumps build/alu.vcd."; \
>	exit 1; \
>}
>$(GTKWAVE) $(VCD)

clean:
>rm -rf $(BUILD_DIR)
