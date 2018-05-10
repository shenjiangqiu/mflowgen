#=========================================================================
# configure.mk
#=========================================================================
# This file will be included inside the Makefile in the build directory

#-------------------------------------------------------------------------
# Step Description
#-------------------------------------------------------------------------
# Build the VCS simulator with options for RTL
#
# This step depends on the "vcs-common-build" step, which is a fake target
# that gathers common VCS build options:
#
# - vcs_common_options
# - vcs_design_options
#
# This step also depends on the "sim-prep" step, which generates the
# Verilog snippet that is `included in the test harness and that contains
# all of the test cases.
#
# X-handling
#
# - There are no X-suppression flags used
#

descriptions.vcs-rtl-build = \
	"RTL -- full X"

#-------------------------------------------------------------------------
# ASCII art
#-------------------------------------------------------------------------

define ascii.vcs-rtl-build
	@echo -e $(echo_green)
	@echo '#--------------------------------------------------------------------------------'
	@echo '# VCS RTL Build -- Full X'
	@echo '#--------------------------------------------------------------------------------'
	@echo -e $(echo_nocolor)
endef

#-------------------------------------------------------------------------
# Alias -- short name for this step
#-------------------------------------------------------------------------

#abbr.vcs-rtl-build =

#-------------------------------------------------------------------------
# RTL-specific structural options
#-------------------------------------------------------------------------
# These are common options across VCS simulation steps, but they need to
# know the exact directory names to set up for the step.

# Specify the simulator binary and simulator compile directory

vcs_rtl_build_simv  = $(handoff_dir.vcs-rtl-build)/simv
vcs_rtl_compile_dir = $(handoff_dir.vcs-rtl-build)/csrc

vcs_rtl_structural_options += -o $(vcs_rtl_build_simv)
vcs_rtl_structural_options += -Mdir=$(vcs_rtl_compile_dir)

# Library files -- Any collected verilog (e.g., SRAMs)

vcs_rtl_structural_options += \
	$(foreach f, $(wildcard $(collect_dir.sim-rtl-build)/*.v),-v $f)

# Include directory -- Any collected includes are made available

vcs_rtl_structural_options += +incdir+$(collect_dir.vcs-rtl-build)

# Dump the bill of materials + file list to help double-check src files

vcs_rtl_structural_options += -bom top
vcs_rtl_structural_options += -bfl $(logs_dir.vcs-rtl-build)/vcs_filelist

#-------------------------------------------------------------------------
# RTL-specific custom options
#-------------------------------------------------------------------------

# Verilog RTL design

sim_dut_v               = $(relative_base_dir)/$(design_v)
vcs_rtl_custom_options += -v $(sim_dut_v)

# Library files -- IO cells

vcs_rtl_custom_options += -v $(adk_dir)/iocells.v

# Performance options for RTL simulation

vcs_rtl_custom_options += -rad

# Disable timing checks

vcs_rtl_custom_options += +notimingcheck +nospecify

# Suppress lint and warnings

vcs_rtl_custom_options += +lint=all,noVCDE,noTFIPC,noIWU,noOUDPE

# Testing library map -- the tests will only use files from this library

vcs_rtl_testing_library  = $(handoff_dir.vcs-rtl-build)/testing.library
vcs_rtl_custom_options  += -libmap $(vcs_rtl_testing_library)

# Design library map -- the design will only use files from this library

vcs_rtl_design_library  = $(handoff_dir.vcs-rtl-build)/design.library
vcs_rtl_custom_options += -libmap $(vcs_rtl_design_library)

#-------------------------------------------------------------------------
# Primary command target
#-------------------------------------------------------------------------
# These are the commands run when executing this step. These commands are
# included into the build Makefile.

vcs_rtl_build_log = $(logs_dir.vcs-rtl-build)/build.log

vcs_rtl_build_cmd = vcs $(vcs_common_options) \
                        $(vcs_design_options) \
                        $(vcs_rtl_structural_options) \
                        $(vcs_rtl_custom_options)

define commands.vcs-rtl-build

	mkdir -p $(logs_dir.vcs-rtl-build)
	mkdir -p $(handoff_dir.vcs-rtl-build)

# Build the testing library map

	echo "library testinglib" \
		$(foreach f, $(testing_files),$(base_dir)/$f,) > $(vcs_rtl_testing_library)
	sed -i "s/,\$$/;/" $(vcs_rtl_testing_library)

# Build the design library map

	echo "library designlib $(base_dir)/$(design_v);" > $(vcs_rtl_design_library)

# Record the options used to build the simulator

	@printf "%.s-" {1..80}        > $(vcs_rtl_build_log)
	@echo                        >> $(vcs_rtl_build_log)
	@echo   "VCS Options"        >> $(vcs_rtl_build_log)
	@printf "%.s-" {1..80}       >> $(vcs_rtl_build_log)
	@echo                        >> $(vcs_rtl_build_log)
	@echo "vcs_common_options = $(vcs_common_options)" \
		>> $(vcs_rtl_build_log)
	@echo "vcs_design_options = $(vcs_design_options)" \
		>> $(vcs_rtl_build_log)
	@echo "vcs_rtl_structural_options = $(vcs_rtl_structural_options)" \
		>> $(vcs_rtl_build_log)
	@echo "vcs_rtl_custom_options = $(vcs_rtl_custom_options)" \
		>> $(vcs_rtl_build_log)

# Record the full command used to build the simulator

	@printf "%.s-" {1..80}       >> $(vcs_rtl_build_log)
	@echo                        >> $(vcs_rtl_build_log)
	@echo   "Full VCS Command"   >> $(vcs_rtl_build_log)
	@printf "%.s-" {1..80}       >> $(vcs_rtl_build_log)
	@echo                        >> $(vcs_rtl_build_log)
	@echo "$(vcs_rtl_build_cmd)" >> $(vcs_rtl_build_log)

# Build the simulator

	@printf "%.s-" {1..80}       >> $(vcs_rtl_build_log)
	@echo                        >> $(vcs_rtl_build_log)
	@echo   "Build log"          >> $(vcs_rtl_build_log)
	@printf "%.s-" {1..80}       >> $(vcs_rtl_build_log)
	@echo                        >> $(vcs_rtl_build_log)
	$(vcs_rtl_build_cmd) | tee -a   $(vcs_rtl_build_log)

endef

#-------------------------------------------------------------------------
# Extra targets
#-------------------------------------------------------------------------
# These are extra useful targets when working with this step. These
# targets are included into the build Makefile.

# Print the VCS build command

print.vcs-rtl-build:
	@echo $(vcs_rtl_build_cmd)

print_list += vcs-rtl-build

# Clean

clean-vcs-rtl-build:
	rm -rf ./$(VPATH)/vcs-rtl-build
	rm -rf ./$(logs_dir.vcs-rtl-build)
	rm -rf ./$(collect_dir.vcs-rtl-build)
	rm -rf ./$(handoff_dir.vcs-rtl-build)

#clean-ex: clean-vcs-rtl-build

