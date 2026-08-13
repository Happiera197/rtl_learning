VERILATOR ?= verilator

TOP       := tb_counter
RTL_DIR   := rtl
TB_DIR    := tb
BUILD_DIR := obj_dir

RTL_SRCS  := $(RTL_DIR)/counter.sv
TB_SRCS   := $(TB_DIR)/tb_counter.sv
SRCS      := $(RTL_SRCS) $(TB_SRCS)

SIM       := $(BUILD_DIR)/V$(TOP)

VERILATOR_FLAGS := \
	--binary \
	--timing \
	--assert \
	--coverage-user \
	-j 1 \
	-Wall \
	-Wno-fatal \
	--top-module $(TOP) \
	--Mdir $(BUILD_DIR)

.PHONY: all lint build sim clean

all: sim

lint:
	$(VERILATOR) --lint-only --timing --assert --coverage-user \
		-Wall -Wno-fatal --top-module $(TOP) $(SRCS)

$(SIM): $(SRCS)
	$(VERILATOR) $(VERILATOR_FLAGS) $(SRCS)

build: $(SIM)

sim: $(SIM)
	./$(SIM)

clean:
	rm -rf $(BUILD_DIR) coverage.dat
