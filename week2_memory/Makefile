SHELL := /bin/bash
.RECIPEPREFIX := >

VERILATOR ?= verilator
GTKWAVE   ?= gtkwave

TOP       := tb_memory
BUILD_DIR := build
OBJ_DIR   := $(BUILD_DIR)/obj_dir
SIM       := $(OBJ_DIR)/sim_memory
VCD       := $(BUILD_DIR)/memory.vcd

RTL_SRCS := \
	rtl/rom16x8.sv \
	rtl/ram16x8_async_read.sv \
	rtl/ram16x8_sync_read.sv

TB_SRCS := \
	tb/tb_memory.sv

SOURCES := $(RTL_SRCS) $(TB_SRCS)

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
>	-o sim_memory \
>	$(SOURCES)

run: build
>./$(SIM)

wave:
>test -f $(VCD) || { \
>	echo "Error: $(VCD) does not exist."; \
>	echo "Run 'make run' before 'make wave'."; \
>	exit 1; \
>}
>$(GTKWAVE) $(VCD)

clean:
>rm -rf $(BUILD_DIR)
