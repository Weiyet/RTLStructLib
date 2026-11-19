DEPTH ?= 16
PRIORITY_WIDTH ?= 8
DATA_WIDTH ?= 8
MIN_FIRST ?= 1
TB_TIMEOUT_CYCLES ?= 100000
TEST ?= priority_vip_boundary_test

PARAMETERS = DEPTH PRIORITY_WIDTH DATA_WIDTH MIN_FIRST
DEFINES += $(foreach param,$(PARAMETERS),+define+PQ_VIP_$(param)=$($(param)))
PLUSARGS += +TB_TIMEOUT_CYCLES=$(TB_TIMEOUT_CYCLES)
CHECK_LOG = python3 sim/check_uvm_log.py

include ../../../Utils/vip/Makefile
