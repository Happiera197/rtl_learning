VERILATOR ?= $(HOME)/verilator/bin/verilator

TOP      := tb_top
OBJ_DIR  := build/obj_dir
BIN      := $(OBJ_DIR)/V$(TOP)
VCD      := fifo_tb.vcd
WAVE_DIR := waves

SRCS := \
	tb/fifo_if.sv \
	rtl/sync_fifo.sv \
	tb/fifo_test.sv \
	tb/tb_top.sv

VFLAGS := \
	--timing \
	--assert \
	-Wall \
	-Wno-fatal \
	-Wno-SYNCASYNCNET

.PHONY: all version lint build sim wave clean

all: lint sim

version:
	$(VERILATOR) --version

lint:
	$(VERILATOR) \
		--lint-only \
		$(VFLAGS) \
		--top-module $(TOP) \
		$(SRCS)

build:
	mkdir -p build $(WAVE_DIR)
	$(VERILATOR) \
		--binary \
		--trace \
		$(VFLAGS) \
		--Mdir $(OBJ_DIR) \
		--top-module $(TOP) \
		$(SRCS)

sim: build
	./$(BIN)
	@if [ -f "$(VCD)" ]; then mv -f "$(VCD)" "$(WAVE_DIR)/$(VCD)"; fi

wave:
	gtkwave $(WAVE_DIR)/$(VCD)

clean:
	rm -rf build
	rm -rf $(WAVE_DIR)
	rm -f $(VCD)
