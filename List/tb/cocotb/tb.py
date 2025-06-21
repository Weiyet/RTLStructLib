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

DUT_DATA_WIDTH = 8
DUT_LENGTH = 8 # Max number of nodes in the list
DUT_SUM_METHOD = 0 # 0: parallel (combo) sum, 1: sequentia sum, 2: adder tree. //ICARUS does not support string overriden to parameter in CLI.

LENGTH_WIDTH = int(math.log2(DUT_LENGTH))
DATA_OUT_WIDTH = LENGTH_WIDTH + DUT_DATA_WIDTH
MAX_VALUE = 2**DUT_DATA_WIDTH - 1

TB_CLK_PERIOD = 30 # TB clk generator
TB_SIM_TIMEOUT = 30 # TB sim timeout 30ms
TB_TEST_WEIGHT = 1

OP_READ = 0b000
OP_INSERT = 0b001
OP_FIND_ALL_INDEX = 0b010
OP_FIND_1ST_INDEX = 0b011
OP_SUM = 0b100
OP_SORT_ASC = 0b101
OP_SORT_DES = 0b110
OP_DELETE = 0b111

err_cnt = 0

#    list #(
#       .DATA_WIDTH(DUT_DATA_WIDTH),
#       .LENGTH(DUT_LENGTH),
#       .SUM_METHOD(DUT_SUM_METHOD)
#    ) DUT (
#       /*input  wire                              */.clk(clk),
#       /*input  wire                              */.rst(rst),
#       /*input  wire [1:0]                        */.op_sel(op_sel),
#       /*input  wire                              */.op_en(op_en),
#       /*input  wire [DATA_WIDTH-1:0]             */.data_in(data_in),
#       /*input  wire [LENGTH_WIDTH-1:0]           */.index_in(index_in),	
#       /*output reg  [LENGTH_WIDTH+DATA_WIDTH-1:0]*/.data_out(data_out),  
#       /*output reg                               */.op_done(op_done),
#       /*output reg                               */.op_in_progress(op_in_progress),
#       /*output reg                               */.op_error(op_error),
#       /*output wire                              */.len(len)
#    );

# Below is not a good way to define "hash_table" in python, but for the sake of simplicity, we define it like this.
list_exp = []

async def list_read(dut, index):
    global list_exp
    global err_cnt
    cocotb.log.info("OP_READ at index %0d", index)
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    dut.op_sel.value = OP_READ
    dut.op_en.value = 1
    dut.index_in.value = index
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    if(dut.op_done.value == 0):
        await RisingEdge(dut.op_done)
    if (index >= len(list_exp)):
        if(dut.op_error.value == 1):
            cocotb.log.info("Data read out of bound, fault flag is asserted correctly")
        else:
            cocotb.log.error("Data read out of bound, fault flag is not asserted")
            err_cnt += 1
    else:
        if (dut.op_error.value == 1):
            cocotb.log.error("Data read is in bound, but fault flag is asserted incorrectly")
            err_cnt += 1
        else:
            if (dut.data_out.value == list_exp[index]):
                cocotb.log.info("Data read: %0d", dut.data_out.value)
            else:
                cocotb.log.error("Data read: %0d, Data Exp: %0d", dut.data_out.value, list_exp[index])
                err_cnt += 1
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Wait for the clock to stabilize
    dut.op_en.value = 0

async def list_read_n_burst(dut, n):
    global list_exp
    global err_cnt
    cocotb.log.info("OP_READ_N_BURST for %d elements", n)
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    dut.op_sel.value = OP_READ
    dut.op_en.value = 1
    dut.index_in.value = 0  # Start reading from index 0
    for i in range(n-1):
        await RisingEdge(dut.clk)
        await Timer(1, units='ns')  # Wait for the clock to stabilize
        if(dut.op_done.value == 0):
            await RisingEdge(dut.op_done)
        if (i >= len(list_exp)):
            if(dut.op_error.value == 1):
                cocotb.log.info("Data read out of bound, fault flag is asserted correctly")
            else:
                cocotb.log.error("Data read out of bound, fault flag is not asserted")
                err_cnt += 1
        else:
            if (dut.op_error.value == 1):
                cocotb.log.error("Data read is in bound, but fault flag is asserted incorrectly")
                err_cnt += 1
            else:
                if (dut.data_out.value == list_exp[i]):
                    cocotb.log.info("Data read: %0d", dut.data_out.value)
                else:
                    cocotb.log.error("Data read: %0d, Data Exp: %0d", dut.data_out.value, list_exp[i])
                    err_cnt += 1
        dut.index_in.value = i + 1  # Update index for the next read
        
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Wait for the clock to stabilize
    dut.op_en.value = 0

async def list_insert(dut, index, value):
    global list_exp
    global err_cnt
    cocotb.log.info("OP_INSERT at index %0d, value %0d", index, value)
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    dut.op_sel.value = OP_INSERT
    dut.op_en.value = 1
    dut.data_in.value = value
    dut.index_in.value = index
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    if(dut.op_done.value == 0):
        await RisingEdge(dut.op_done)
    
    if (len(list_exp) >= DUT_LENGTH):
        if(dut.op_error.value == 1):
            cocotb.log.info("Data insert out of bound, fault flag is asserted correctly")
        else:
            cocotb.log.error("Data insert out of bound, fault flag is not asserted")
            err_cnt += 1
    else:
        if (dut.op_error.value == 1):
            cocotb.log.error("Data insert is in bound, but fault flag is asserted incorrectly")
            err_cnt += 1    
        if (index >= len(list_exp)):
            list_exp.append(value)  # Update the expected list content
        else:
            list_exp.insert(index, value)  # Insert the value at the specified inde
            
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Wait for the clock to stabilize
    dut.op_en.value = 0

    cocotb.log.info("List content after insert: %s", list_exp)

async def list_delete(dut, index):
    global list_exp
    global err_cnt
    cocotb.log.info("OP_DELETE at index %0d", index)
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    dut.op_sel.value = OP_DELETE
    dut.op_en.value = 1
    dut.index_in.value = index
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    if(dut.op_done.value == 0):
        await RisingEdge(dut.op_done)
    
    if (index >= len(list_exp)):
        if(dut.op_error.value == 1):
            cocotb.log.info("Data delete out of bound, fault flag is asserted correctly")
        else:
            cocotb.log.error("Data delete out of bound, fault flag is not asserted")
            err_cnt += 1
    else:
        if (dut.op_error.value == 1):
            cocotb.log.error("Data delete is in bound, but fault flag is asserted incorrectly")
            err_cnt += 1
        list_exp.pop(index)  # Update the expected list content
    
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Wait for the clock to stabilize
    dut.op_en.value = 0

    cocotb.log.info("List content after delete: %s", list_exp)

async def list_sum(dut):
    global list_exp
    global err_cnt
    cocotb.log.info("OP_SUM")
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    dut.op_sel.value = OP_SUM
    dut.op_en.value = 1
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    if (dut.op_done.value == 0):
        await RisingEdge(dut.op_done)
    
    if (dut.op_error.value == 1):
        cocotb.log.error("Sum operation failed, fault flag is asserted incorrectly")
        err_cnt += 1

    expected_sum = sum(list_exp)
    if (dut.data_out.value == expected_sum):
        cocotb.log.info("Sum result: %0d", dut.data_out.value)
    else:
        cocotb.log.error("Sum result: %0d, Expected: %0d", dut.data_out.value, expected_sum)
        err_cnt += 1
    
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Wait for the clock to stabilize
    dut.op_en.value = 0

async def list_sort_ascending(dut):
    global list_exp
    global err_cnt
    cocotb.log.info("OP_SORT_ASC")
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    dut.op_sel.value = OP_SORT_ASC
    dut.op_en.value = 1
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    if (dut.op_done.value == 0):
        await RisingEdge(dut.op_done)
    
    if (dut.op_error.value == 1):
        cocotb.log.error("Sort ascending operation failed, fault flag is asserted incorrectly")
        err_cnt += 1

    list_exp.sort()
    
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Wait for the clock to stabilize
    dut.op_en.value = 0

    cocotb.log.info("List content after sort ascending: %s", list_exp)

async def list_sort_descending(dut):
    global list_exp
    global err_cnt
    cocotb.log.info("OP_SORT_DES")
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    dut.op_sel.value = OP_SORT_DES
    dut.op_en.value = 1
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    if (dut.op_done.value == 0):
        await RisingEdge(dut.op_done)
    
    if (dut.op_error.value == 1):
        cocotb.log.error("Sort descending operation failed, fault flag is asserted incorrectly")
        err_cnt += 1

    list_exp.sort(reverse=True)
    
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Wait for the clock to stabilize
    dut.op_en.value = 0

    cocotb.log.info("List content after sort descending: %s", list_exp)

async def list_find_1st_index(dut, value):
    global list_exp
    global err_cnt
    cocotb.log.info("OP_FIND_1ST_INDEX for value %0d", value)
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    dut.op_sel.value = OP_FIND_1ST_INDEX
    dut.op_en.value = 1
    dut.data_in.value = value
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    if(dut.op_done.value == 0):
        await RisingEdge(dut.op_done)

    if value in list_exp:
        if (dut.op_error.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        expected_index = list_exp.index(value)
        if (dut.data_out.value == expected_index):
            cocotb.log.info("First index found: %0d", dut.data_out.value)
        else:
            cocotb.log.error("First index found: %0d, Expected: %0d", dut.data_out.value, expected_index)
            err_cnt += 1
    else:
        if (dut.op_error.value == 1):
            cocotb.log.info("Index is not found in list, fault flag is asserted correctly")
        else:
            cocotb.log.error("Index is not found in list, but fault flag is not asserted")
            err_cnt += 1
    
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Wait for the clock to stabilize
    dut.op_en.value = 0

async def list_find_all_index(dut, value):
    global list_exp
    global err_cnt
    cocotb.log.info("OP_FIND_ALL_INDEX for value %0d", value)
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    dut.op_sel.value = OP_FIND_ALL_INDEX
    dut.op_en.value = 1
    dut.data_in.value = value
    await RisingEdge(dut.clk)
    await Timer (1, units='ns')  # Wait for the clock to stabilize
    indices = [i for i, x in enumerate(list_exp) if x == value]
    cnt = 0
    if indices:
        while (cnt < len(indices)):
            if(dut.op_done.value == 1):
                if(indices[cnt] == dut.data_out.value):
                    cocotb.log.info("Value %0d found at index %0d", value, dut.data_out.value)
                else:
                    cocotb.log.error("Value %0d found at index %0d, Expected: %0d", value, dut.data_out.value, indices[cnt])
                    err_cnt += 1
                cnt += 1
            if(cnt <= (len(indices)-1) & dut.op_in_progress.value == 0):
                cocotb.log.error("OP_FIND_ALL_INDEX all idex is not found, but op_in_progress is deasserted incorrectly")
            if (dut.op_error.value == 1):
                cocotb.log.error("Fault flag is asserted incorrectly")
                err_cnt += 1
            await RisingEdge(dut.clk)
            await Timer(1, units='ns')
    else:
        if (dut.op_done.value == 1):
            await RisingEdge(dut.op_done)
        if (dut.op_error.value == 1):
            cocotb.log.info("Indices are not found in list, fault flag is asserted correctly")
        else:
            cocotb.log.error("Indices are not found in list, but fault flag is not asserted")
            err_cnt += 1
    
    await RisingEdge(dut.clk)
    await Timer(1, units='ns')  # Wait for the clock to stabilize
    dut.op_en.value = 0

async def dut_init(dut):
    global DUT_DATA_WIDTH
    global DUT_LENGTH 
    global DUT_SUM_METHOD 
    global LENGTH_WIDTH 
    global DATA_OUT_WIDTH 
    global MAX_VALUE 
    global list_exp

    DUT_DATA_WIDTH = dut.DATA_WIDTH.value
    DUT_LENGTH = dut.LENGTH.value
    DUT_SUM_METHOD = dut.SUM_METHOD.value  # 0: parallel (combo) sum, 1: sequential sum, 2: adder tree
    LENGTH_WIDTH = int(math.log2(DUT_LENGTH))
    DATA_OUT_WIDTH = LENGTH_WIDTH + DUT_DATA_WIDTH
    MAX_VALUE = 2**DUT_DATA_WIDTH - 1

    await cocotb.start(Clock(dut.clk, TB_CLK_PERIOD, units='ns').start())  # Start the clock generator
    dut.rst.value = 1
    dut.op_en.value = 0
    dut.op_sel.value = 0
    dut.data_in.value = 0
    dut.index_in.value = 0
    dut._log.info("DUT reset")
    list_exp = []
    await Timer(10, units='ns')
    dut.rst.value = 0
    await Timer(10, units='ns')
    cocotb.log.info("DUT reset done")

async def timeout():
    await Timer(TB_SIM_TIMEOUT, units='ms')
    cocotb.log.error("Simulation timeout")
    raise cocotb.result.TestFailure("Simulation timeout")

@cocotb.test()
async def basic_op_test(dut):
    #timeout_task = asyncio.create_task(timeout())
    cocotb.start_soon(timeout())
    await dut_init(dut)
    cocotb.log.info("SEED NUMBER = %d",cocotb.RANDOM_SEED)
    
    await list_insert(dut, 0, random.randint(0,2**DUT_DATA_WIDTH-1))
    await list_insert(dut, 1, random.randint(0,2**DUT_DATA_WIDTH-1))
    await list_insert(dut, 2, random.randint(0,2**DUT_DATA_WIDTH-1))
    await list_insert(dut, 3, list_exp[2])
    await list_insert(dut, 4, list_exp[0])

    await list_read(dut, 0)
    await list_read(dut, 1)
    await list_read(dut, 2)
    await list_read(dut, 3)
    await list_read(dut, 4)
    await list_read(dut, 5) # This should trigger an out-of-bounds error

    await list_delete(dut, 5) # This should trigger an out-of-bounds error
    await list_delete(dut, 3)

    await list_sum(dut)

    await list_sort_ascending(dut)
    await list_read_n_burst(dut, 5)
    
    await list_sort_descending(dut)
    await list_read_n_burst(dut, 5)

    await list_find_1st_index(dut, list_exp[1])
    await list_find_all_index(dut, list_exp[2])
    #timeout_task.cancel()
    #task.kill()

    if (err_cnt > 0):
        cocotb.log.error("Errors count = %d",err_cnt)
        raise cocotb.result.TestFailure() 
