VERILATOR ?= verilator
TOP       := tb_rv_buffer_1entry
RTL       := rtl/rv_buffer_1entry.sv
TB        := tb/rv_assertions.sv tb/tb_rv_buffer_1entry.sv
OBJ_DIR   := obj_dir_rv

FLAGS := --timing --assert -Wall -Wno-fatal --top-module $(TOP)

.PHONY: all lint sim clean

all: lint sim

lint:
	$(VERILATOR) --lint-only $(FLAGS) $(RTL) $(TB)

sim:
	$(VERILATOR) --binary $(FLAGS) --Mdir $(OBJ_DIR) $(RTL) $(TB)
	./$(OBJ_DIR)/V$(TOP)

clean:
	$(RM) -r $(OBJ_DIR) obj_dir
	$(RM) *.vcd *.fst *.log
