CAPACITY ?= 16
TB_TIMEOUT_CYCLES ?= 20000
TEST ?= bitmap_vip_boundary_test
DEFINES += +define+BITMAP_VIP_CAPACITY=$(CAPACITY)
PLUSARGS += +TB_TIMEOUT_CYCLES=$(TB_TIMEOUT_CYCLES)
CHECK_LOG = python3 ../../../Utils/vip/check_uvm_log.py

include ../../../Utils/vip/Makefile
