VERILATOR ?= verilator

TOP = tb_sync_fifo

RTL = rtl/sync_fifo.sv

TB = \
	tb/tb_sync_fifo.sv


VFLAGS = \
	--binary \
	--timing \
	--trace \
	--assert \
	-Wall \
	-Wno-fatal \
	-Itb


.PHONY: all lint sim wave clean


all: lint sim


lint:
	$(VERILATOR) \
		--lint-only \
		--timing \
		--assert \
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


wave:
	gtkwave fifo.vcd


clean:
	rm -rf obj_dir_fifo
	rm -f fifo.vcd
	rm -f *.log
