WPWD=$(shell pwd)
VERILOG_SOURCES = $(WPWD)/../../rtl/verilog/bootloaderModule.v
VERILOG_SOURCES += $(WPWD)/../../rtl/verilog/contador_up.v
VERILOG_SOURCES += $(WPWD)/../../rtl/verilog/registro.v
VERILOG_SOURCES += $(WPWD)/../../rtl/verilog/pulse_button.v
VERILOG_SOURCES += $(WPWD)/../../rtl/verilog/biestable_d.v
VERILOG_SOURCES += $(WPWD)/../../rtl/verilog/and_gate.v


TOPLEVEL := bootloader_module
MODULE   := test_bootloader_module

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
