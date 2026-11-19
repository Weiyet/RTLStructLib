# pyUVM uses the same simulator, parameters, waves and result checks as cocotb TBs.
PYUVM_RULES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
export PYTHONPATH := $(abspath $(PYUVM_RULES_DIR)/../../..):$(PYTHONPATH)
include $(PYUVM_RULES_DIR)../../tb/cocotb/Makefile
