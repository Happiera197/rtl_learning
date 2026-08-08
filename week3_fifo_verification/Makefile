VERILATOR ?= verilator

TOP  := tb_sync_fifo
RTL  := rtl/sync_fifo.sv
TB   := tb/tb_sync_fifo.sv
MDIR := obj_dir_fifo
BIN  := $(MDIR)/V$(TOP)

VFLAGS := --binary --timing --trace --assert -Wall -Wno-fatal

.PHONY: all lint sim clean

all: lint sim

lint:
	$(VERILATOR) --lint-only --timing --assert -Wall -Wno-fatal \
		--top-module $(TOP) \
		$(RTL) $(TB)

sim:
	rm -rf $(MDIR)
	$(VERILATOR) $(VFLAGS) \
		--Mdir $(MDIR) \
		--top-module $(TOP) \
		$(RTL) $(TB)
	./$(BIN)

clean:
	rm -rf $(MDIR) obj_dir \
		*.vcd *.fst *.log
