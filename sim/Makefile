PWD = $(shell pwd)/..
export PYTHONPATH = $(PWD)/python_tb/

#defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

export COCOTB_ANSI_OUTPUT = 1

VERILOG_SOURCES += $(PWD)/src/*.sv
VERILOG_SOURCES += $(PWD)/tb/*.sv

TOPLEVEL = spi_tb

MODULE = spi_tests

include $(shell cocotb-config --makefiles)/Makefile.sim

wave:
	gtkwave $(PWD)/sim/waves/$(TOPLEVEL).vcd
