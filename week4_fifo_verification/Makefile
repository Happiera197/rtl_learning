VERILATOR ?= verilator
VERILATOR_COVERAGE ?= verilator_coverage

TOP = tb_sync_fifo

RTL = rtl/sync_fifo.sv

TB = \
	tb/tb_sync_fifo.sv


VFLAGS = \
	--binary \
	--timing \
	--trace \
	--assert \
	--coverage-user \
	-Wall \
	-Wno-fatal \
	-Itb


.PHONY: all lint sim coverage wave clean


all: lint sim


lint:
	$(VERILATOR) \
		--lint-only \
		--timing \
		--assert \
		--coverage-user \
		-Wall \
		-Wno-fatal \
		-Itb \
		$(RTL) \
		$(TB)


sim:
	rm -rf obj_dir_fifo

	$(VERILATOR) \
		$(VFLAGS) \
		--Mdir obj_dir_fifo \
		--top-module $(TOP) \
		$(RTL) \
		$(TB)

	./obj_dir_fifo/V$(TOP)


coverage: sim
	$(VERILATOR_COVERAGE) --report summary,hier coverage.dat


wave:
	gtkwave fifo.vcd


clean:
	rm -rf obj_dir_fifo
	rm -f fifo.vcd
	rm -f coverage.dat
	rm -f *.log
