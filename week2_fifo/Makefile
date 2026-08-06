VERILATOR ?= verilator

VFLAGS := --binary --timing --trace --assert -Wall -Wno-fatal

.PHONY: all lint sim sim_fifo sim_rv wave_fifo wave_rv clean

all: lint sim

lint:
	verilator --lint-only --assert -Wall -Wno-fatal \
		--top-module sync_fifo \
		rtl/sync_fifo.sv

	verilator --lint-only --assert -Wall -Wno-fatal \
		--top-module rv_buffer_1entry \
		rtl/rv_buffer_1entry.sv
sim: sim_fifo sim_rv

sim_fifo:
	rm -rf obj_dir_fifo sync_fifo.vcd
	$(VERILATOR) $(VFLAGS) \
		--Mdir obj_dir_fifo \
		--top-module tb_sync_fifo \
		rtl/sync_fifo.sv tb/tb_sync_fifo.sv
	./obj_dir_fifo/Vtb_sync_fifo

sim_rv:
	rm -rf obj_dir_rv rv_buffer_1entry.vcd
	$(VERILATOR) $(VFLAGS) \
		--Mdir obj_dir_rv \
		--top-module tb_rv_buffer_1entry \
		rtl/rv_buffer_1entry.sv tb/tb_rv_buffer_1entry.sv
	./obj_dir_rv/Vtb_rv_buffer_1entry

wave_fifo:
	gtkwave sync_fifo.vcd

wave_rv:
	gtkwave rv_buffer_1entry.vcd

clean:
	rm -rf obj_dir obj_dir_fifo obj_dir_rv \
		sync_fifo.vcd rv_buffer_1entry.vcd
