# ============================================================
# Week4 FIFO Verification Makefile
# ============================================================

VERILATOR ?= verilator

# ------------------------------------------------------------
# Common options
# ------------------------------------------------------------

VFLAGS := --binary \
          --timing \
          --assert \
          --trace-fst \
          -Wall \
          -Wno-fatal \
          -Itb


# ------------------------------------------------------------
# Source files
# ------------------------------------------------------------

RTL := rtl/sync_fifo.sv

FIFO_TRANSACTION := tb/fifo_transaction.sv
FIFO_TB          := tb/tb_sync_fifo.sv
TRANSACTION_TB   := tb/tb_transaction.sv


# ------------------------------------------------------------
# Top modules
# ------------------------------------------------------------

FIFO_TOP        := tb_sync_fifo
TRANSACTION_TOP := tb_transaction


# ------------------------------------------------------------
# Build directories
# ------------------------------------------------------------

FIFO_OBJ        := obj_dir_fifo
TRANSACTION_OBJ := obj_dir_transaction


# ------------------------------------------------------------
# Runtime options
# ------------------------------------------------------------

TEST ?= basic
SEED ?= 12345
TRACE ?= 0

TESTS := basic reset full_empty simultaneous_rw random

TRACE_ARG := $(if $(filter 1,$(TRACE)),+TRACE,)


# ------------------------------------------------------------
# Phony targets
# ------------------------------------------------------------

.PHONY: all \
        lint lint_rtl lint_fifo lint_transaction \
        build_fifo build_transaction \
        sim sim_fifo sim_transaction \
        basic reset full_empty simultaneous_rw random \
        regression \
        wave \
        clean \
        help


# ============================================================
# Default
# ============================================================

all: lint regression


# ============================================================
# Lint
# ============================================================

lint: lint_rtl lint_fifo lint_transaction


lint_rtl:
	@echo "========================================"
	@echo "Lint RTL"
	@echo "========================================"
	$(VERILATOR) \
		--lint-only \
		-Wall \
		-Wno-fatal \
		--top-module sync_fifo \
		$(RTL)


lint_fifo:
	@echo "========================================"
	@echo "Lint FIFO Testbench"
	@echo "========================================"
	$(VERILATOR) \
		--lint-only \
		--timing \
		--assert \
		-Wall \
		-Wno-fatal \
		-Itb \
		--top-module $(FIFO_TOP) \
		$(RTL) \
		$(FIFO_TRANSACTION) \
		$(FIFO_TB)


lint_transaction:
	@echo "========================================"
	@echo "Lint Transaction Testbench"
	@echo "========================================"
	$(VERILATOR) \
		--lint-only \
		--timing \
		-Wall \
		-Wno-fatal \
		-Itb \
		--top-module $(TRANSACTION_TOP) \
		$(TRANSACTION_TB)


# ============================================================
# Build
# ============================================================

build_fifo:
	@echo "========================================"
	@echo "Build FIFO Testbench"
	@echo "========================================"

	rm -rf $(FIFO_OBJ)

	$(VERILATOR) $(VFLAGS) \
		--Mdir $(FIFO_OBJ) \
		--top-module $(FIFO_TOP) \
		$(RTL) \
		$(FIFO_TRANSACTION) \
		$(FIFO_TB)


build_transaction:
	@echo "========================================"
	@echo "Build Transaction Testbench"
	@echo "========================================"

	rm -rf $(TRANSACTION_OBJ)

	$(VERILATOR) $(VFLAGS) \
		--Mdir $(TRANSACTION_OBJ) \
		--top-module $(TRANSACTION_TOP) \
		$(TRANSACTION_TB)


# ============================================================
# Simulation
# ============================================================

sim: sim_fifo


sim_fifo: build_fifo
	@echo ""
	@echo "========================================"
	@echo "Run FIFO Simulation"
	@echo "TEST = $(TEST)"
	@echo "SEED = $(SEED)"
	@echo "========================================"

	./$(FIFO_OBJ)/V$(FIFO_TOP) \
		+TEST=$(TEST) \
		+verilator+seed+$(SEED) \
		$(TRACE_ARG)


sim_transaction: build_transaction
	@echo ""
	@echo "========================================"
	@echo "Run Transaction Test"
	@echo "SEED = $(SEED)"
	@echo "========================================"

	./$(TRANSACTION_OBJ)/V$(TRANSACTION_TOP) \
		+verilator+seed+$(SEED)


# ============================================================
# Individual FIFO Tests
# ============================================================

basic:
	$(MAKE) sim_fifo TEST=basic SEED=$(SEED)


reset:
	$(MAKE) sim_fifo TEST=reset SEED=$(SEED)


full_empty:
	$(MAKE) sim_fifo TEST=full_empty SEED=$(SEED)


simultaneous_rw:
	$(MAKE) sim_fifo TEST=simultaneous_rw SEED=$(SEED)


random:
	$(MAKE) sim_fifo TEST=random SEED=$(SEED)


# ============================================================
# Regression
# ============================================================

regression: build_fifo
	@echo ""
	@echo "========================================"
	@echo "FIFO Regression"
	@echo "SEED = $(SEED)"
	@echo "========================================"

	@set -e; \
	for test in $(TESTS); do \
		echo ""; \
		echo "----------------------------------------"; \
		echo "Running TEST=$$test"; \
		echo "----------------------------------------"; \
		./$(FIFO_OBJ)/V$(FIFO_TOP) \
			+TEST=$$test \
			+verilator+seed+$(SEED); \
	done

	@echo ""
	@echo "========================================"
	@echo "FIFO Regression PASS"
	@echo "========================================"


# ============================================================
# Waveform
# ============================================================

wave:
	$(MAKE) sim_fifo \
		TEST=$(TEST) \
		SEED=$(SEED) \
		TRACE=1

	@if [ -f sync_fifo.fst ]; then \
		gtkwave sync_fifo.fst; \
	else \
		echo "ERROR: sync_fifo.fst was not generated"; \
		exit 1; \
	fi


# ============================================================
# Clean
# ============================================================

clean:
	rm -rf \
		obj_dir \
		$(FIFO_OBJ) \
		$(TRANSACTION_OBJ) \
		*.fst \
		*.vcd \
		*.log \
		coverage.dat


# ============================================================
# Help
# ============================================================

help:
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  make lint"
	@echo "      Run RTL and testbench lint"
	@echo ""
	@echo "  make sim_transaction"
	@echo "      Run fifo_transaction class test"
	@echo ""
	@echo "  make basic"
	@echo "      Run basic FIFO test"
	@echo ""
	@echo "  make reset"
	@echo "      Run reset test"
	@echo ""
	@echo "  make full_empty"
	@echo "      Run full/empty boundary test"
	@echo ""
	@echo "  make simultaneous_rw"
	@echo "      Run simultaneous read/write test"
	@echo ""
	@echo "  make random"
	@echo "      Run randomized FIFO test"
	@echo ""
	@echo "  make random SEED=12345"
	@echo "      Run reproducible randomized test"
	@echo ""
	@echo "  make regression"
	@echo "      Run all FIFO tests"
	@echo ""
	@echo "  make wave TEST=random SEED=12345"
	@echo "      Run test and open FST waveform"
	@echo ""
	@echo "  make clean"
	@echo "      Remove generated files"
	@echo ""
