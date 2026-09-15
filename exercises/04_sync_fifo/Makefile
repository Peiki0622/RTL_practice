# Shared per-exercise simulation entry points.
# All tool-generated files must stay under .sim/<variant>/.

SHELL := /bin/bash

MAKEFILE_SELF := $(abspath $(lastword $(MAKEFILE_LIST)))
EXERCISE_DIR := $(patsubst %/,%,$(dir $(MAKEFILE_SELF)))
GOLDEN_DIR := $(EXERCISE_DIR)/golden
PRACTICE_DIR := $(EXERCISE_DIR)/practice
TB_DIR := $(EXERCISE_DIR)/testbench

BUILD_ROOT := $(EXERCISE_DIR)/.sim
GOLDEN_BUILD := $(BUILD_ROOT)/golden
PRACTICE_BUILD := $(BUILD_ROOT)/practice

TB_TOP ?= tb
DUT_INSTANCE ?= dut
VCS ?= vcs
VERDI ?= verdi

VCS_FLAGS ?= -full64 -sverilog -debug_access+all -kdb -timescale=1ns/1ps
VCS_EXTRA_FLAGS ?=
SIM_FLAGS ?=
VERDI_FLAGS ?= -full64
VERDI_EXTRA_FLAGS ?=

GOLDEN_SRCS = $(sort $(wildcard $(GOLDEN_DIR)/*.sv))
PRACTICE_SRCS = $(sort $(wildcard $(PRACTICE_DIR)/*.sv))
TB_SRCS = $(sort $(wildcard $(TB_DIR)/*.sv))
VERDI_SCRIPT := $(TB_DIR)/verdi.tcl

.PHONY: help vcs-golden vcs-practice verdi-golden verdi-practice clean \
        check-vcs check-verdi check-golden check-practice check-testbench check-verdi-script

help:
	@echo "Targets:"
	@echo "  make vcs-golden      Compile and simulate golden RTL with VCS"
	@echo "  make verdi-golden    Run golden simulation, then open FSDB in Verdi"
	@echo "  make vcs-practice    Compile and simulate practice RTL with VCS"
	@echo "  make verdi-practice  Run practice simulation, then open FSDB in Verdi"
	@echo "  make clean           Remove all generated simulation artifacts"

check-vcs:
	@command -v "$(VCS)" >/dev/null 2>&1 || { echo "ERROR: VCS executable not found: $(VCS)"; exit 1; }

check-verdi:
	@command -v "$(VERDI)" >/dev/null 2>&1 || { echo "ERROR: Verdi executable not found: $(VERDI)"; exit 1; }

check-golden:
	@test -n "$(strip $(GOLDEN_SRCS))" || { echo "ERROR: no golden SystemVerilog source found in $(GOLDEN_DIR)"; exit 1; }

check-practice:
	@test -n "$(strip $(PRACTICE_SRCS))" || { echo "ERROR: no practice SystemVerilog source found in $(PRACTICE_DIR)"; exit 1; }

check-testbench:
	@test -n "$(strip $(TB_SRCS))" || { echo "ERROR: no testbench SystemVerilog source found in $(TB_DIR)"; exit 1; }

check-verdi-script:
	@test -f "$(VERDI_SCRIPT)" || { echo "ERROR: missing $(VERDI_SCRIPT); Codex must provide a Verdi replay script that adds and colors the required signals."; exit 1; }

vcs-golden: check-vcs check-golden check-testbench
	@mkdir -p "$(GOLDEN_BUILD)"
	@echo "[VCS] golden -> $(GOLDEN_BUILD)"
	@cd "$(GOLDEN_BUILD)" && \
		"$(VCS)" $(VCS_FLAGS) $(VCS_EXTRA_FLAGS) $(GOLDEN_SRCS) $(TB_SRCS) \
		-top "$(TB_TOP)" -o simv -l vcs_compile.log
	@cd "$(GOLDEN_BUILD)" && ./simv $(SIM_FLAGS) -l vcs_sim.log
	@test -f "$(GOLDEN_BUILD)/wave.fsdb" || { echo "ERROR: golden simulation did not create $(GOLDEN_BUILD)/wave.fsdb"; echo "       The testbench must call \$$fsdbDumpfile(\"wave.fsdb\") and dump the required hierarchy."; exit 1; }

vcs-practice: check-vcs check-practice check-testbench
	@mkdir -p "$(PRACTICE_BUILD)"
	@echo "[VCS] practice -> $(PRACTICE_BUILD)"
	@cd "$(PRACTICE_BUILD)" && \
		"$(VCS)" $(VCS_FLAGS) $(VCS_EXTRA_FLAGS) $(PRACTICE_SRCS) $(TB_SRCS) \
		-top "$(TB_TOP)" -o simv -l vcs_compile.log
	@cd "$(PRACTICE_BUILD)" && ./simv $(SIM_FLAGS) -l vcs_sim.log
	@test -f "$(PRACTICE_BUILD)/wave.fsdb" || { echo "ERROR: practice simulation did not create $(PRACTICE_BUILD)/wave.fsdb"; echo "       The testbench must call \$$fsdbDumpfile(\"wave.fsdb\") and dump the required hierarchy."; exit 1; }

verdi-golden: vcs-golden check-verdi check-verdi-script
	@echo "[Verdi] golden waveform -> $(GOLDEN_BUILD)/wave.fsdb"
	@cd "$(GOLDEN_BUILD)" && \
		"$(VERDI)" $(VERDI_FLAGS) $(VERDI_EXTRA_FLAGS) \
		-dbdir simv.daidir -ssf wave.fsdb -play "$(VERDI_SCRIPT)" &

verdi-practice: vcs-practice check-verdi check-verdi-script
	@echo "[Verdi] practice waveform -> $(PRACTICE_BUILD)/wave.fsdb"
	@cd "$(PRACTICE_BUILD)" && \
		"$(VERDI)" $(VERDI_FLAGS) $(VERDI_EXTRA_FLAGS) \
		-dbdir simv.daidir -ssf wave.fsdb -play "$(VERDI_SCRIPT)" &

clean:
	@rm -rf "$(BUILD_ROOT)"
	@rm -rf "$(EXERCISE_DIR)/csrc" "$(EXERCISE_DIR)/simv" "$(EXERCISE_DIR)/simv.daidir" \
		"$(EXERCISE_DIR)/DVEfiles" "$(EXERCISE_DIR)/verdiLog" \
		"$(EXERCISE_DIR)/ucli.key" "$(EXERCISE_DIR)/novas.conf" "$(EXERCISE_DIR)/novas.rc"
	@rm -f "$(EXERCISE_DIR)"/*.fsdb "$(EXERCISE_DIR)"/*.vpd "$(EXERCISE_DIR)"/*.vcd \
		"$(EXERCISE_DIR)"/*.log
	@echo "Removed all generated simulation artifacts for $(EXERCISE_DIR)"
