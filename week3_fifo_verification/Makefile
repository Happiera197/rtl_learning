VERILATOR ?= verilator

TOP := tb_sync_fifo
RTL := rtl/sync_fifo.sv
TB  := tb/tb_sync_fifo.sv

MDIR := obj_dir_fifo
BIN  := $(MDIR)/V$(TOP)

WAVE    := sync_fifo.fst
LOG_DIR := logs

TEST  ?= basic
TESTS := basic reset full_empty simultaneous_rw random

VFLAGS := --binary --timing --trace-fst --assert -Wall -Wno-fatal
LFLAGS := --lint-only --timing --assert -Wall -Wno-fatal


# ============================================================
# Coverage configuration
# ============================================================

COV_MDIR := obj_dir_cov
COV_BIN  := $(COV_MDIR)/V$(TOP)

COV_DIR      := coverage
COV_DATA_DIR := $(COV_DIR)/data
COV_ANN_DIR  := $(COV_DIR)/annotated
COV_MERGED   := $(COV_DIR)/coverage_merged.dat

COV_FLAGS := --binary --timing --assert -Wall -Wno-fatal \
	     --coverage-line --coverage-toggle


.PHONY: all lint build sim wave regress clean
.PHONY: coverage coverage_build coverage_run coverage_report


# ============================================================
# Normal verification flow
# ============================================================

all: regress


lint:
	$(VERILATOR) $(LFLAGS) \
		--top-module $(TOP) \
		$(RTL) $(TB)


$(BIN): $(RTL) $(TB)
	$(VERILATOR) $(VFLAGS) \
		--Mdir $(MDIR) \
		--top-module $(TOP) \
		$(RTL) $(TB)


build: $(BIN)


sim: build
	./$(BIN) +TEST=$(TEST)


wave: build
	rm -f $(WAVE)
	./$(BIN) +TEST=$(TEST) +TRACE
	gtkwave $(WAVE)


regress: lint build
	@rm -rf $(LOG_DIR)
	@mkdir -p $(LOG_DIR)
	@pass=0; fail=0; \
	echo "========================================"; \
	echo "FIFO Regression"; \
	echo "========================================"; \
	for test in $(TESTS); do \
		printf "%-18s : " "$$test"; \
		if ./$(BIN) +TEST=$$test > $(LOG_DIR)/$$test.log 2>&1; then \
			echo "PASS"; \
			pass=$$((pass + 1)); \
		else \
			echo "FAIL"; \
			fail=$$((fail + 1)); \
		fi; \
	done; \
	echo "----------------------------------------"; \
	echo "Passed : $$pass"; \
	echo "Failed : $$fail"; \
	if [ $$fail -eq 0 ]; then \
		echo "RESULT : PASS"; \
	else \
		echo "RESULT : FAIL"; \
		echo "Check $(LOG_DIR)/ for failure details."; \
		exit 1; \
	fi; \
	echo "========================================"


# ============================================================
# Coverage flow
# ============================================================

coverage_build:
	rm -rf $(COV_MDIR)
	$(VERILATOR) $(COV_FLAGS) \
		--Mdir $(COV_MDIR) \
		--top-module $(TOP) \
		$(RTL) $(TB)


coverage_run: coverage_build
	rm -rf $(COV_DIR)
	mkdir -p $(COV_DATA_DIR)
	mkdir -p $(LOG_DIR)

	@set -e; \
	for t in $(TESTS); do \
		echo "========================================"; \
		echo "Coverage test: $$t"; \
		echo "========================================"; \
		./$(COV_BIN) \
			+TEST=$$t \
			+verilator+coverage+file+$(COV_DATA_DIR)/$$t.dat \
			> $(LOG_DIR)/coverage_$$t.log 2>&1; \
		cat $(LOG_DIR)/coverage_$$t.log; \
	done

	verilator_coverage \
		--write $(COV_MERGED) \
		$(COV_DATA_DIR)/*.dat


coverage_report: coverage_run
	verilator_coverage \
		--report summary \
		$(COV_MERGED) \
		| tee $(COV_DIR)/summary.txt

	rm -rf $(COV_ANN_DIR)

	verilator_coverage \
		--annotate $(COV_ANN_DIR) \
		--annotate-points \
		--annotate-min 1 \
		$(COV_MERGED)


coverage: coverage_report


# ============================================================
# Clean
# ============================================================

clean:
	rm -rf $(MDIR) \
		$(COV_MDIR) \
		obj_dir \
		$(LOG_DIR) \
		$(COV_DIR) \
		*.fst *.vcd *.log \
		coverage.dat
