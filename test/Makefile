# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
WAVES ?= 1
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = project.v

# Component testing support
# Usage: make COMPONENT=row_decoder | column_decoder | column_mux | write_driver
COMPONENT ?= 

ifeq ($(COMPONENT),row_decoder)
	VERILOG_SOURCES = $(SRC_DIR)/sram_utils.v $(SRC_DIR)/row_decoder.v $(PWD)/testbenches/tb_row_decoder.v
	TOPLEVEL = tb_row_decoder
	COCOTB_TEST_MODULES = tests.test_row_decoder
	SIM_BUILD = sim_build/row_decoder
endif

ifeq ($(COMPONENT),column_decoder)
	VERILOG_SOURCES = $(SRC_DIR)/sram_utils.v $(SRC_DIR)/column_decoder.v $(PWD)/testbenches/tb_column_decoder.v
	TOPLEVEL = tb_column_decoder
	COCOTB_TEST_MODULES = tests.test_column_decoder
	SIM_BUILD = sim_build/column_decoder
endif

ifeq ($(COMPONENT),column_mux)
	VERILOG_SOURCES = $(SRC_DIR)/column_mux.v $(PWD)/testbenches/tb_column_mux.v
	TOPLEVEL = tb_column_mux
	COCOTB_TEST_MODULES = tests.test_column_mux
	SIM_BUILD = sim_build/column_mux
endif

ifeq ($(COMPONENT),write_driver)
	VERILOG_SOURCES = $(SRC_DIR)/sram_utils.v $(SRC_DIR)/write_driver.v $(PWD)/testbenches/tb_write_driver.v
	TOPLEVEL = tb_write_driver
	COCOTB_TEST_MODULES = tests.test_write_driver
	SIM_BUILD = sim_build/write_driver
endif

ifeq ($(COMPONENT),control_fsm)
	VERILOG_SOURCES = $(SRC_DIR)/sram_control.v $(PWD)/testbenches/tb_control_fsm.v
	TOPLEVEL = tb_control_fsm
	COCOTB_TEST_MODULES = tests.test_control_fsm
	SIM_BUILD = sim_build/control_fsm
endif

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				?= sim_build/rtl
# Include all source files for integration test
VERILOG_SOURCES ?= $(SRC_DIR)/sram_utils.v \
                   $(SRC_DIR)/project.v \
                   $(SRC_DIR)/sram_core.v \
                   $(SRC_DIR)/sram_control.v \
                   $(SRC_DIR)/row_decoder.v \
                   $(SRC_DIR)/column_decoder.v \
                   $(SRC_DIR)/column_mux.v \
                   $(SRC_DIR)/write_driver.v

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
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

# Include the testbench sources:
VERILOG_SOURCES ?= $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
VERILOG_SOURCES += $(PWD)/testbenches/tb.v
TOPLEVEL ?= tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES ?= tests.test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

# Convenience target to test all components
.PHONY: test_all
test_all:
	@echo "=========================================="
	@echo "Testing Row Decoder..."
	@echo "=========================================="
	@$(MAKE) clean
	@$(MAKE) COMPONENT=row_decoder
	@echo ""
	@echo "=========================================="
	@echo "Testing Column Decoder..."
	@echo "=========================================="
	@$(MAKE) clean
	@$(MAKE) COMPONENT=column_decoder
	@echo ""
	@echo "=========================================="
	@echo "Testing Column Mux..."
	@echo "=========================================="
	@$(MAKE) clean
	@$(MAKE) COMPONENT=column_mux
	@echo ""
	@echo "=========================================="
	@echo "Testing Write Driver..."
	@echo "=========================================="
	@$(MAKE) clean
	@$(MAKE) COMPONENT=write_driver
	@echo ""
	@echo "=========================================="
	@echo "Testing Control FSM..."
	@echo "=========================================="
	@$(MAKE) clean
	@$(MAKE) COMPONENT=control_fsm
	@echo ""
	@echo "=========================================="
	@echo "Testing Full SRAM Integration..."
	@echo "=========================================="
	@$(MAKE) clean
	@$(MAKE)
	@echo ""
	@echo "=========================================="
	@echo "✅ ALL TESTS COMPLETE"
	@echo "=========================================="
	@echo ""
	@echo "Waveforms generated:"
	@echo "  waveforms/tb_row_decoder.vcd"
	@echo "  waveforms/tb_column_decoder.vcd"
	@echo "  waveforms/tb_column_mux.vcd"
	@echo "  waveforms/tb_write_driver.vcd"
	@echo "  waveforms/tb_control_fsm.vcd"
	@echo "  waveforms/tb.vcd (full integration)"
	@echo ""
	@echo "View with: gtkwave waveforms/<file>.vcd"
