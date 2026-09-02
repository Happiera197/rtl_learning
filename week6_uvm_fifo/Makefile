VERILATOR ?= verilator
VERILATOR_COVERAGE ?= verilator_coverage
UVM_HOME ?= /home/happier/uvm-core/src
TOP       ?= tb_top
BUILD_DIR ?= obj_dir
COVERAGE_DIR ?= coverage

COVERAGE_DATA      := $(COVERAGE_DIR)/coverage.dat
COVERAGE_SUMMARY   := $(COVERAGE_DIR)/summary.txt
COVERAGE_ANNOTATED := $(COVERAGE_DIR)/annotated

SOURCES := \
	$(UVM_HOME)/uvm_pkg.sv \
	tb/fifo_if.sv \
	tb/fifo_pkg.sv \
	rtl/sync_fifo.sv \
	tb/tb_top.sv

VFLAGS := \
	--binary \
	--timing \
	--assert \
	-Wall \
	-Wno-fatal \
	-Wno-VARHIDDEN \
	-DUVM_NO_DPI \
	-I$(UVM_HOME) \
	-Itb \
	--top-module $(TOP) \
	--Mdir $(BUILD_DIR) \
	-j 4

COVERAGE_FLAGS := \
	--coverage-line \
	--coverage-toggle \
	--coverage-user

.PHONY: all build run test coverage coverage_report clean

all: build

build:
	$(VERILATOR) $(VFLAGS) $(SOURCES)

run: build
	./$(BUILD_DIR)/V$(TOP)

test: run

coverage:
	mkdir -p $(COVERAGE_DIR)
	$(VERILATOR) $(VFLAGS) $(COVERAGE_FLAGS) $(SOURCES)
	./$(BUILD_DIR)/V$(TOP) +verilator+coverage+file+$(COVERAGE_DATA)

coverage_report: coverage
	$(VERILATOR_COVERAGE) --report summary $(COVERAGE_DATA) > $(COVERAGE_SUMMARY)
	$(VERILATOR_COVERAGE) --annotate $(COVERAGE_ANNOTATED) $(COVERAGE_DATA)

clean:
	rm -rf $(BUILD_DIR) $(COVERAGE_DIR)
