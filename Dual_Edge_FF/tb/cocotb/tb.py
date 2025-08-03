import random
#import asyncio
import math
import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge, ReadOnly
from cocotb.clock import Clock
from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor
from cocotb.binary import BinaryValue

#BIN string
#BinaryValue(dut.data_wr.value, n_bits=8) ; BinaryValue.integar ; BinaryValue.hex ; BinaryValue.binstr; BinaryValue.signed_integer ; can represent x,z

DUT_DATA_WIDTH = 8 # DUT paramter
DUT_RESET_VALUE = 0 # DUT parameter
TB_CLK_PERIOD = 30 # TB clk generator
TB_SIM_TIMEOUT = 30 # TB sim timeout 30ms
TB_TEST_WEIGHT = 1

err_cnt = 0

#    dual_edge_ff #(
#         .DATA_WIDTH(DUT_DATA_WIDTH),   
#         .RESET_VALUE(DUT_RESET_VALUE) 
#     ) DUT (
#        /*input  wire                  */.clk(clk),
#        /*input  wire                  */.rst_n(rst_n),
#        /*input  wire [DATA_WIDTH-1:0] */.data_in(data_in),
#        /*input  wire [DATA_WIDTH-1:0] */.pos_edge_latch_en(pos_edge_latch_en),
#        /*input  wire [DATA_WIDTH-1:0] */.neg_edge_latch_en(neg_edge_latch_en),
#        /*output wire [DATA_WIDTH-1:0] */.data_out(data_out)
#     );

async def dut_init(dut):
    global DUT_DATA_WIDTH  # DUT parameter
    global DUT_RESET_VALUE # DUT parameter
    DUT_DATA_WIDTH = dut.DATA_WIDTH.value
    DUT_RESET_VALUE = dut.RESET_VALUE.value
    await cocotb.start(Clock(dut.clk, TB_CLK_PERIOD, units="ns").start())
    dut.data_in.value = 0
    dut.pos_edge_latch_en.value = 0
    dut.neg_edge_latch_en.value = 0
    dut.rst_n.value = 0
    await(Timer(100,'ns'))
    dut.rst_n.value = 1
    await(Timer(100,'ns'))
    

@cocotb.test()
async def direct_test(dut):
    global err_cnt
    await dut_init(dut)
    cocotb.log.info("SEED NUMBER = %d",cocotb.RANDOM_SEED)

    for j in range(TB_TEST_WEIGHT):
        for i in range(20):
            k = random.randint(0, 3)
            match k:
                case 0: # positive edge only 
                    input_data = random.randint(0, 2**DUT_DATA_WIDTH)
                    await FallingEdge(dut.clk)
                    await Timer(1, units='ns')
                    dut.data_in.value = input_data
                    dut.pos_edge_latch_en.value = 2**DUT_DATA_WIDTH - 1
                    await RisingEdge(dut.clk)
                    await(Timer(1, units='ns'))
                    if(dut.data_out.value != input_data):
                        cocotb.log.error("Data out is incorrect at posedge, EXP: %0d, ACT: %0d", input_data, dut.data_out.value)
                        err_cnt += 1
                    else:
                        cocotb.log.info("Data out is correct at posedge with value %0d", dut.data_out.value)
                    
                    dut.data_in.value = input_data + 1
                    await FallingEdge(dut.clk)
                    await(Timer(1, units='ns'))
                    if(dut.data_out.value != input_data):
                        cocotb.log.error("Data out is incorrect, should not be updated at negedge, EXP: %0d, ACT: %0d", input_data + 1, dut.data_out.value)
                        err_cnt += 1
                    dut.pos_edge_latch_en.value = 0
                case 1: # negative edge only
                    input_data = random.randint(0, 2**DUT_DATA_WIDTH)
                    await RisingEdge(dut.clk)
                    await Timer(1, units='ns')
                    dut.data_in.value = input_data
                    dut.neg_edge_latch_en.value = 2**DUT_DATA_WIDTH - 1
                    await FallingEdge(dut.clk)
                    await(Timer(1, units='ns'))
                    if(dut.data_out.value != input_data):
                        cocotb.log.error("Data out is incorrect at negedge, EXP: %0d, ACT: %0d", input_data, dut.data_out.value)
                        err_cnt += 1
                    else:
                        cocotb.log.info("Data out is correct at negedge with value %0d", dut.data_out.value)

                    dut.data_in.value = input_data + 1
                    await RisingEdge(dut.clk)
                    await(Timer(1, units='ns'))
                    if(dut.data_out.value != input_data):
                        cocotb.log.error("Data out is incorrect, should not be updated at posedge, EXP: %0d, ACT: %0d", input_data + 1, dut.data_out.value)
                        err_cnt += 1
                    dut.neg_edge_latch_en.value = 0
                
                case 2: # both edges
                    input_data = random.randint(0, 2**DUT_DATA_WIDTH)
                    await FallingEdge(dut.clk)
                    await Timer(1, units='ns')
                    dut.data_in.value = input_data
                    dut.pos_edge_latch_en.value = 2**DUT_DATA_WIDTH - 1
                    dut.neg_edge_latch_en.value = 2**DUT_DATA_WIDTH - 1
                    await RisingEdge(dut.clk)
                    await(Timer(1, units='ns'))
                    if(dut.data_out.value != input_data):
                        cocotb.log.error("Data out is incorrect at posedge, EXP: %0d, ACT: %0d", input_data, dut.data_out.value)
                        err_cnt += 1
                    else:
                        cocotb.log.info("Data out is correct at posedge with value %0d", dut.data_out.value)

                    input_data = random.randint(0, 2**DUT_DATA_WIDTH)
                    dut.data_in.value = input_data 
                    await FallingEdge(dut.clk)
                    await(Timer(1, units='ns'))
                    if(dut.data_out.value != input_data):
                        cocotb.log.error("Data out is incorrect at negedge, EXP: %0d, ACT: %0d", input_data, dut.data_out.value)
                        err_cnt += 1
                    else:
                        cocotb.log.info("Data out is correct at negedge with value %0d", dut.data_out.value)

                    dut.pos_edge_latch_en.value = 0
                    dut.neg_edge_latch_en.value = 0
    
    if (err_cnt > 0):
        cocotb.log.error("Errors count = %d",err_cnt)
        #cocotb.result.test_fail()
        #assert False, f"Test failed with {err_cnt} errors"
        raise cocotb.result.TestFailure(f"Test failed with {err_cnt} errors")
