import random
import asyncio
import math
import cocotb
import cocotb.result
from cocotb.triggers import Timer, RisingEdge, ReadOnly, with_timeout
from cocotb.clock import Clock
from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor
from cocotb.binary import BinaryValue

#BIN string
#BinaryValue(dut.data_wr.value, n_bits=8) ; BinaryValue.integar ; BinaryValue.hex ; BinaryValue.binstr; BinaryValue.signed_integer ; can represent x,z

DUT_KEY_WIDTH = 32
DUT_VALUE_WIDTH = 32
DUT_TOTAL_INDEX = 8
DUT_CHAINING_SIZE = 4
DUT_COLLISION_METHOD = "MULTI_STAGE_CHAINING" 
DUT_HASH_ALGORITHM = "MODULUS"

MAX_VALUE = 2**DUT_VALUE_WIDTH - 1
INDEX_WIDTH = int(math.log2(DUT_TOTAL_INDEX))
ADDR_WIDTH = int(math.log2(DUT_TOTAL_INDEX*DUT_CHAINING_SIZE))

OP_INSERT = 0b00
OP_DELTE = 0b01
OP_SEARCH = 0b10

TB_CLK_PERIOD = 30 # TB clk generator
TB_SIM_TIMEOUT = 30 # TB sim timeout 30ms
TB_TEST_WEIGHT = 1
err_cnt = 1

    # hash_table #(
    #           .KEY_WIDTH(DUT_KEY_WIDTH),
    #           .VALUE_WIDTH(DUT_VALUE_WIDTH),
    #           .TOTAL_INDEX(DUT_TOTAL_INDEX),  // Total index of the hash table
    #           .CHAINING_SIZE(DUT_CHAINING_SIZE), // Number of chains for SINGLE_CYCLE_CHAINING and MULTI_STAGE_CHAINING only
    #           .COLLISION_METHOD(DUT_COLLISION_METHOD),  // "MULTI_STAGE_CHAINING", "LINEAR_PROBING" 
    #           .HASH_ALGORITHM(DUT_HASH_ALGORITHM))  // "MODULUS", "SHA1", "FNV1A")) 
    #           DUT (
    # /*input wire*/                   .clk(clk),
    # /*input wire*/                   .rst(rst),
    # /*input wire [KEY_WIDTH-1:0]*/   .key_in(key_in),
    # /*input wire [VALUE_WIDTH-1:0]*/ .value_in(value_in),
    # /*input wire [1:0]*/             .op_sel(op_sel), // 00: Insert, 01: Delete, 10: Search
    # /*input wire*/                   .op_en(op_en),
    # /*output reg [VALUE_WIDTH-1:0]*/ .value_out(value_out),
    # /*output reg*/                   .op_done(op_done),
    # /*output reg*/                   .op_error(op_error), // FULL when insert FAIL, KEY_NOT_FOUND when delete or search FAIL
    # /*output reg [CHAIN_WIDTH-1:0]*/ .collision_count(collision_count));

# Below is not a good way to define "hash_table" in python, but for the sake of simplicity, we define it like this.
class hash_table:
    def __init__(self, dut):
        self.dut = dut
        self.key_value_pair = [{} for j in range(DUT_TOTAL_INDEX)]

    def hash(self, key):
        if DUT_HASH_ALGORITHM == "MODULUS":
            return key % DUT_TOTAL_INDEX
        elif DUT_HASH_ALGORITHM == "SHA1":
            # Implement SHA1 hash function here
            pass
        elif DUT_HASH_ALGORITHM == "FNV1A":
            # Implement FNV1A hash function here
            pass

    def insert(self, key, value):
        index = self.hash(key)
        if len(self.key_value_pair[index]) < DUT_CHAINING_SIZE:
            self.key_value_pair[index][key] = value
            cocotb.log.info("Inserted key: %d, value: %d at index: %d", key, value, index)
            return True
        else:
            cocotb.log.info("Collision occurred at index: %d", index)
            return False

    def delete(self, key):
        index = self.hash(key)
        if key in self.key_value_pair[index]:
            del self.key_value_pair[index][key]
            cocotb.log.info("Deleted key: %d at index: %d", key, index)
            return True
        else:
            cocotb.log.info("Key not found: %d at index: %d", key, index)
            return False

    def search(self, key):
        index = self.hash(key)
        if key in self.key_value_pair[index]:
            cocotb.log.info("Found key: %d, value: %d at index: %d", key, self.key_value_pair[index][key], index)
            return self.key_value_pair[index][key]
        else:
            cocotb.log.info("Key not found: %d at index: %d", key, index)
            return -1
        
    def print_content(self):
        cocotb.log.info("Hash Table Content:")
        for i in range(DUT_TOTAL_INDEX):
            info = "index " + str(i) + " : " + str(self.key_value_pair[i])
            cocotb.log.info(info)
        cocotb.log.info("End of Hash Table Content")
        
async def hash_table_insert(dut, hash_table, key, value):
    global err_cnt
    cocotb.log.info("OP_Insert key: %0d, value: %0d", key, value)
    await RisingEdge(dut.clk)
    await Timer (1, units = 'ns')
    dut.key_in.value = key
    dut.value_in.value = value
    dut.op_sel.value = OP_INSERT
    dut.op_en.value = 1
    await RisingEdge(dut.op_done)
    await Timer (1, units = 'ns')
    result = hash_table.insert(key, value)
    if (result == False):
        if(dut.op_error.value == 1):
            cocotb.log.info("Collision occurred, error flag is asserted correctly")
        else:
            cocotb.log.error("Collision occurred, error flag is not asserted")
            err_cnt += 1
    await RisingEdge(dut.clk)
    dut.op_en.value = 0 
    hash_table.print_content()

async def hash_table_delete(dut, hash_table, key):
    global err_cnt
    cocotb.log.info("OP_Delete key: %0d", key)
    await RisingEdge(dut.clk)
    await Timer (1, units = 'ns')
    dut.key_in.value = key
    dut.op_sel.value = OP_DELTE
    dut.op_en.value = 1
    await RisingEdge(dut.op_done)
    await Timer (1, units = 'ns')
    result = hash_table.delete(key)
    if (result == False):
        if(dut.op_error.value == 1):
            cocotb.log.info("Key not found, error flag is asserted correctly")
        else:
            cocotb.log.error("Key not found, error flag is not asserted")
            err_cnt += 1
    await RisingEdge(dut.clk)
    dut.op_en.value = 0 
    hash_table.print_content()

async def hash_table_search(dut, hash_table, key):
    global err_cnt
    cocotb.log.info("OP_Search key: %0d", key)
    await RisingEdge(dut.clk)
    await Timer (1, units = 'ns')
    dut.key_in.value = key
    dut.op_sel.value = OP_SEARCH
    dut.op_en.value = 1
    cocotb.log.info("hello")
    await RisingEdge(dut.op_done)
    cocotb.log.info("hello2")
    await Timer (1, units = 'ns')
    await ReadOnly()
    result = hash_table.search(key)
    if (result == -1):
        if(dut.op_error.value == 1):
            cocotb.log.info("Key not found, error flag is asserted correctly")
        else:
            cocotb.log.error("Key not found, error flag is not asserted")
            err_cnt += 1
    else:
        if(dut.value_out.value == result):
            cocotb.log.info("Key found, value: %0d", result)
        else:
            cocotb.log.error("Key found, but value is not correct")
            err_cnt += 1
    await RisingEdge(dut.clk)
    dut.op_en.value = 0 
    hash_table.print_content()
    return -1 if (dut.op_error.value) else dut.value_out.value
    


async def dut_init(dut):
    global DUT_KEY_WIDTH 
    global DUT_VALUE_WIDTH
    global DUT_TOTAL_INDEX 
    global DUT_CHAINING_SIZE
    global MAX_VALUE 
    global INDEX_WIDTH
    global ADDR_WIDTH

    DUT_KEY_WIDTH = dut.KEY_WIDTH.value
    DUT_VALUE_WIDTH = dut.VALUE_WIDTH.value
    DUT_TOTAL_INDEX = dut.TOTAL_INDEX.value
    DUT_CHAINING_SIZE = dut.CHAINING_SIZE.value
    DUT_COLLISION_METHOD = dut.COLLISION_METHOD.value
    DUT_HASH_ALGORITHM = dut.HASH_ALGORITHM.value
    MAX_VALUE = 2**DUT_VALUE_WIDTH - 1
    INDEX_WIDTH = int(math.log2(DUT_TOTAL_INDEX))
    ADDR_WIDTH = int(math.log2(DUT_TOTAL_INDEX*DUT_CHAINING_SIZE))

    await cocotb.start(Clock(dut.clk, TB_CLK_PERIOD, units="ns").start())
    dut.rst.value = 0
    dut.key_in.value = 0
    dut.value_in.value = 0
    dut.op_sel.value = 0
    dut.op_en.value = 0
    dut.rst.value = 1
    await(Timer(100,'ns'))
    dut.rst.value = 0
    await(Timer(100,'ns'))

async def timeout():
    await Timer(TB_SIM_TIMEOUT, units='ms')
    cocotb.log.error("Simulation timeout")
    raise cocotb.result.TestFailure("Simulation timeout")

@cocotb.test()
async def direct_basic_op_test(dut):
    #timeout_task = asyncio.create_task(timeout())
    cocotb.start_soon(timeout())
    await dut_init(dut)
    exp_hash_table = hash_table(dut)
    cocotb.log.info("SEED NUMBER = %d",cocotb.RANDOM_SEED)
    await hash_table_insert(dut, exp_hash_table, 1, 2)
    result = await hash_table_search(dut, exp_hash_table, 1)
    await hash_table_insert(dut, exp_hash_table, 3, 2)
    await hash_table_insert(dut, exp_hash_table, 11, 3)
    await hash_table_insert(dut, exp_hash_table, 19, 4)
    await hash_table_insert(dut, exp_hash_table, 27, 5)
    await hash_table_insert(dut, exp_hash_table, 35, 5)
    await hash_table_insert(dut, exp_hash_table, 43, 5)
    await hash_table_delete(dut, exp_hash_table, 1)
    result = await hash_table_search(dut, exp_hash_table, 19)
    result = await hash_table_search(dut, exp_hash_table, 1)
    result = await hash_table_search(dut, exp_hash_table, 3)
    
    #timeout_task.cancel()
    #task.kill()

    if (err_cnt > 0):
        cocotb.log.error("Errors count = %d",err_cnt)
        raise cocotb.result.TestFailure() 
