VERILATOR ?= verilator

COMMON_FLAGS := --assert -Wall -Wno-fatal
LINT_FLAGS   := --lint-only --timing $(COMMON_FLAGS)
SIM_FLAGS    := --binary --timing --trace $(COMMON_FLAGS)

FIFO_TOP  := tb_sync_fifo
FIFO_RTL  := rtl/sync_fifo.sv
FIFO_TB   := tb/tb_sync_fifo.sv
FIFO_MDIR := obj_dir_fifo
FIFO_VCD  := sync_fifo.vcd

RV_TOP  := tb_rv_buffer_1entry
RV_RTL  := rtl/rv_buffer_1entry.sv
RV_TB   := tb/tb_rv_buffer_1entry.sv
RV_MDIR := obj_dir_rv
RV_VCD  := rv_buffer_1entry.vcd

.PHONY: all lint lint_fifo lint_rv \
        sim sim_fifo sim_rv \
        wave_fifo wave_rv clean

all: lint sim


# ============================================================
# Lint
# ============================================================

lint: lint_fifo lint_rv

lint_fifo:
	$(VERILATOR) $(LINT_FLAGS) \
		--top-module $(FIFO_TOP) \
		$(FIFO_RTL) \
		$(FIFO_TB)

lint_rv:
	$(VERILATOR) $(LINT_FLAGS) \
		--top-module $(RV_TOP) \
		$(RV_RTL) \
		$(RV_TB)


# ============================================================
# Simulation
# ============================================================

sim: sim_fifo sim_rv

sim_fifo:
	rm -rf $(FIFO_MDIR) $(FIFO_VCD)
	$(VERILATOR) $(SIM_FLAGS) \
		--Mdir $(FIFO_MDIR) \
		--top-module $(FIFO_TOP) \
		$(FIFO_RTL) \
		$(FIFO_TB)
	./$(FIFO_MDIR)/V$(FIFO_TOP)

sim_rv:
	rm -rf $(RV_MDIR) $(RV_VCD)
	$(VERILATOR) $(SIM_FLAGS) \
		--Mdir $(RV_MDIR) \
		--top-module $(RV_TOP) \
		$(RV_RTL) \
		$(RV_TB)
	./$(RV_MDIR)/V$(RV_TOP)


# ============================================================
# Waveform
# ============================================================

wave_fifo:
	gtkwave $(FIFO_VCD)

wave_rv:
	gtkwave $(RV_VCD)


# ============================================================
# Clean
# ============================================================

clean:
	rm -rf obj_dir $(FIFO_MDIR) $(RV_MDIR) \
		$(FIFO_VCD) $(RV_VCD)
