VERILATOR ?= verilator
UVM_HOME ?= /home/happier/uvm-core/src
TOP       ?= tb_top
BUILD_DIR ?= obj_dir

SOURCES := \
	$(UVM_HOME)/uvm_pkg.sv \
	tb/fifo_if.sv \
	tb/fifo_pkg.sv \
	rtl/sync_fifo.sv \
	tb/tb_top.sv

VFLAGS := \
	--binary \
	--timing \
	-Wall \
	-Wno-fatal \
	-Wno-VARHIDDEN \
	-DUVM_NO_DPI \
	-I$(UVM_HOME) \
	-Itb \
	--top-module $(TOP) \
	--Mdir $(BUILD_DIR) \
	-j 4

.PHONY: all build run test clean

all: build

build:
	$(VERILATOR) $(VFLAGS) $(SOURCES)

run: build
	./$(BUILD_DIR)/V$(TOP)

test: run

clean:
	rm -rf $(BUILD_DIR)
