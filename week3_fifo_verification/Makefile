VERILATOR ?= verilator

TOP  := tb_sync_fifo
RTL  := rtl/sync_fifo.sv
TB   := tb/tb_sync_fifo.sv

MDIR := obj_dir_fifo
BIN  := $(MDIR)/V$(TOP)

WAVE    := sync_fifo.fst
LOG_DIR := logs

TEST  ?= basic
TESTS := basic reset full_empty simultaneous_rw random

VFLAGS := --binary --timing --trace-fst --assert -Wall -Wno-fatal
LFLAGS := --lint-only --timing --assert -Wall -Wno-fatal


.PHONY: all lint build sim wave regress clean


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


clean:
	rm -rf $(MDIR) obj_dir \
		$(LOG_DIR) \
		*.fst *.vcd *.log \
		coverage.dat coverage_report
