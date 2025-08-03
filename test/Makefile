# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = font.sv peripheral.sv
ADDITIONAL_SOURCES = tt_wrapper.v test_harness/*.sv

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl

VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(ADDITIONAL_SOURCES))

else

# Gate level simulation:
SIM_BUILD		 = sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

ifeq ($(SIM),verilator)
COMPILE_ARGS 		+= --timing
EXTRA_ARGS 			+= --trace
endif


ifeq ($(MODEL),yes)
SRC_DPI_JSON = ../simio/JSON.sv/sv/util.sv ../simio/JSON.sv/sv/json.sv
SRC_MODELS_GUI = ../../simio/sock.sv/sock.c $(SRC_DPI_JSON) ../../simio/components/verilog/ssd1306/simio_ssd1306_spi4.sv

INC_SOCK = ../simio/sock.sv/sock.sv
INC_JSON = ../simio/JSON.sv/sv/json.svh

VERILOG_SOURCES += $(SRC_MODELS_GUI)
COMPILE_ARGS += -I $(INC_JSON) -I  $(INC_SOCK) --relative-includes --build -DMODEL
endif

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# MODULE is the basename of the Python test file
MODULE = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
