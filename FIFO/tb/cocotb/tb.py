import random
#import asyncio
import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

DEPTH = 12 # DUT parameter
DATA_WIDTH = 8 # DUT paramter
ASYNC = 1 # DUT parameter
TEST_WEIGHT = 1 # TB multiplier for stimulus injected
WR_CLK_PERIOD = 20 # TB wr_clk generator
RD_CLK_PERIOD = 32 # TB rd_clk generator
#SIM_TIMEOUT = 100000; // TB simulation time out
BURST_LENGHT = DEPTH
MAX_DATA = 2**DATA_WIDTH - 1

# fifo #(
# .DEPTH(DEPTH), 
# .DATA_WIDTH(DATA_WIDTH), 
# .ASYNC(ASYNC)) DUT (
    # /*input wire*/ .rd_clk(rd_clk),
    # /*input wire*/ .wr_clk(wr_clk),
    # /*input wire*/ .rst(rst),
    # /*input wire [DATA_WIDTH-1:0]*/ .data_wr(data_wr),
    # /*input wire*/ .wr_en(wr_en),
    # /*output wire*/ .fifo_full(fifo_full),
    # /*output wire [DATA_WIDTH-1:0]*/ .data_rd(data_rd),
    # /*input wire*/ .rd_en(rd_en),
    # /*output wire*/ .fifo_empty(fifo_empty));

async def dut_init(dut):
    global DEPTH 
    global DATA_WIDTH
    global ASYNC 
    global MAX_DATA
    global BURST_LENGHT
    DEPTH = dut.DEPTH.value 
    DATA_WIDTH = dut.DATA_WIDTH.value
    ASYNC = dut.ASYNC.value
    MAX_DATA = 2**DATA_WIDTH - 1
    BURST_LENGHT = DEPTH
    await cocotb.start(Clock(dut.wr_clk, WR_CLK_PERIOD, units="ns").start())
    await cocotb.start(Clock(dut.rd_clk, RD_CLK_PERIOD, units="ns").start())
    dut.rst.value = 1
    await(Timer(1000,'ns'))
    dut.rst.value = 0
    await(Timer(1000,'ns'))

async def fifo_write_burst_rand(count,dut,fifo_expected):
    for i in range(count):
        await RisingEdge(dut.wr_clk)
        await(Timer(1,'ns'))
        if(len(fifo_expected) < DEPTH and dut.fifo_full.value == 1):
            dut._log.error("FIFO is not full but fifo_full flag is asserted")
        dut.wr_en.value = 1
        data_wr_rand = random.randint(0,MAX_DATA)
        dut.data_wr.value = data_wr_rand
        if(len(fifo_expected) < DEPTH):
            fifo_expected.append(data_wr_rand)
            dut._log.info("Data written = %d, FIFO entry = %d", data_wr_rand, len(fifo_expected))
        else:
            await(Timer(1,'ns'))
            if(dut.fifo_full.value == 1):
                dut._log.info("FIFO is full, fifo_full flag is asserted correctly")
            else:
                dut._log.error("FIFO is full but fifo_full flag is not asserted")
    await RisingEdge(dut.wr_clk)
    await(Timer(1,'ns'))
    dut.wr_en.value = 0


async def fifo_read_burst(count,dut,fifo_expected):
    for i in range(count):
        await RisingEdge(dut.rd_clk)
        await Timer(1,'ns')
        dut.rd_en.value = 1
        await Timer(1,'ns')
        if(len(fifo_expected)>0):
            if(dut.fifo_empty.value == 1):
                dut._log.error("FIFO is not empty but fifo_empty flag is asserted")
            data_rd_exp = fifo_expected.pop(0)
            data_rd_act = dut.data_rd.value.integer
            if(data_rd_exp == data_rd_act):
                dut._log.info("Data read = %d, FIFO entry = %d", data_rd_act, len(fifo_expected))
            else:
                dut._log.error("Data read mismatch, ACT = %d, EXP = %d", data_rd_act, data_rd_exp)
        else:
            if(dut.fifo_empty.value == 1):
                dut._log.info("FIFO is empty, fifo_empty flag is asserted correctly")
            else:
                dut._log.error("FIFO is empty but fifo_empty flag is not asserted")
    dut.rd_en.value = 0

async def fifo_burst_write(dut,fifo_wr_stream,fifo_expected):
    for data_wr in fifo_wr_stream:
        await RisingEdge(dut.wr_clk)
        await Timer(1,'ns')
        dut.wr_en.value = 1
        dut.data_wr.value = data_wr
        fifo_expected.append(data_wr)
        dut._log.info("Data written = %d, FIFO entry = %d", data_wr, len(fifo_expected))
    await RisingEdge(dut.wr_clk)
    await Timer(1,'ns')
    dut.wr_en.value = 0

async def fifo_burst_read_return_stream(dut,count,fifo_expected):
    fifo_rd_stream = []
    while (len(fifo_rd_stream) < count):
        await RisingEdge(dut.rd_clk)
        await Timer(1,'ns')
        dut.rd_en.value = 1
        await Timer(1,'ns')
        if(dut.fifo_empty.value != 1):
            data_rd = dut.data_rd.value.integer
            fifo_rd_stream.append(data_rd)
            fifo_expected.pop(0)
            dut._log.info("Data read = %d, FIFO entry = %d", data_rd,len(fifo_expected))
    dut.rd_en.value = 0
    return fifo_rd_stream

async def fifo_read_write_rand_simul(count,dut):
    fifo_wr_stream = []
    fifo_rd_stream = []
    for i in range(BURST_LENGHT):
        data_wr_rand = random.randint(0,MAX_DATA+1)
        fifo_wr_stream.append(data_wr_rand)
    fifo_expected = []
    await cocotb.start(fifo_burst_write(dut,fifo_wr_stream,fifo_expected))
    fifo_rd_stream = await fifo_burst_read_return_stream(dut,BURST_LENGHT,fifo_expected)
    for i in range(len(fifo_wr_stream)):
        if(fifo_wr_stream[i] != fifo_rd_stream[i]):
            dut._log.error("Data rd %d does not match data wr %d", fifo_rd_stream[i],fifo_wr_stream[i])
    

@cocotb.test()
async def fifo_rand_write_then_read_test(dut):
    await dut_init(dut)
    dut._log.info("\nFIFO WRITE BURST SEQ")
    fifo_expected = []
    await fifo_write_burst_rand(DEPTH+3,dut,fifo_expected)
    await(Timer(1000,'ns'))
    dut._log.info("\nFIFO READ BURST SEQ")
    await fifo_read_burst(DEPTH+3,dut,fifo_expected)
    await(Timer(1000,'ns'))


@cocotb.test()
async def fifo_rand_read_write_test(dut):
    await dut_init(dut)
    dut._log.info("\nFIFO RANDOM READ WRITE SEQ")
    fifo_expected = []
    i = DEPTH
    while(i >= 0):
        op_sel = random.randint(0,1)
        op_count = random.randint(1,5)
        i = i - op_count
        match (op_sel):
            case 1:
                await fifo_read_burst(op_count,dut,fifo_expected)
                await Timer(RD_CLK_PERIOD,'ns')
                await Timer(3*WR_CLK_PERIOD,'ns')
            case 0: 
                await fifo_write_burst_rand(op_count,dut,fifo_expected)
                await Timer(WR_CLK_PERIOD,'ns')
                await Timer(3*RD_CLK_PERIOD,'ns')
    
@cocotb.test()
async def fifo_rand_read_write_simul_test(dut):
    await dut_init(dut)
    dut._log.info("\nFIFO SIMULTANEOUS RANDOM READ WRITE SEQ")
    await fifo_read_write_rand_simul(1,dut)

