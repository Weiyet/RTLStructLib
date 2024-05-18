import random
#import asyncio
import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly
from cocotb.clock import Clock
from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor

DEPTH = 12 # DUT parameter
DATA_WIDTH = 8 # DUT paramter
TEST_WEIGHT = 1 # TB multiplier for stimulus injected
CLK_PERIOD = 20 # TB clk generator
#SIM_TIMEOUT = 100000; // TB simulation time out
MAX_DATA = 2**DATA_WIDTH - 1
err_cnt = 0

# lifo #(
# .DEPTH(DEPTH), 
# .DATA_WIDTH(DATA_WIDTH)) DUT (
#     /*input wire*/ .clk(clk),
#     /*input wire*/ .rst(rst),
#     /*input wire [DATA_WIDTH-1:0]*/ .data_wr(data_wr),
#     /*input wire*/ .wr_en(wr_en),
#     /*output reg*/ .lifo_full(lifo_full),
#     /*output reg [DATA_WIDTH-1:0]*/ .data_rd(data_rd),
#     /*input wire*/ .rd_en(rd_en),
#     /*output wire*/ .lifo_empty(lifo_empty));

class OutputDriver(BusDriver):
    _signals = ["wr_en", "rd_en", "data_wr"] #dut.wr_en ; dut.rd_en; dut.data_wr

    def __init__(self, dut, name, clk):
        BusDriver.__init__(self, dut, name, clk)
        self.bus.wr_en.value = 0
        self.bus.rd_en.value = 0
        self.dut = dut
        self.clk = clk

    async def _driver_send(self, op_sel, op_count):
        match op_sel:
            case 0:
                wr_data_array = []
                for i in range (op_count):
                    wr_data_array.append(random.randint(0,MAX_DATA))
                await self.lifo_write(wr_data_array)
            case 1:
                await self.lifo_read(op_count)
            case 2:
                wr_data_array = []
                for i in range (op_count):
                    wr_data_array.append(random.randint(0,MAX_DATA))
                await self.lifo_read_write_simul(wr_data_array)

    async def lifo_write(self, wr_data_array):
        data_w = 0
        while len(wr_data_array) != 0:
            await RisingEdge(self.clk)
            await Timer (1, units = 'ns')
            self.bus.wr_en.value = 1
            data_w = wr_data_array.pop()
            self.bus.data_wr.value = data_w
            self.dut._log.info("Driver: Writting Data = %d",data_w)
        await RisingEdge(self.clk)
        self.bus.wr_en.value = 0
        
    async def lifo_read(self,op_count):
        for i in range(op_count):
            await RisingEdge(self.clk)
            self.bus.rd_en.value = 1
            self.dut._log.info("Driver: Reading Data = %d",)
        await RisingEdge(self.clk)
        await Timer (1, units='ns')
        self.bus.rd_en.value = 0

    async def lifo_read_write_simul(self,wr_data_array):
        data_w = 0
        while len(wr_data_array) != 0:
            await RisingEdge(self.clk)
            await Timer (1, units = 'ns')
            self.bus.rd_en.value = 1
            self.bus.wr_en.value = 1
            data_w = wr_data_array.pop()
            self.bus.data_wr.value = data_w    
            self.dut._log.info("Driver: Simultanenous read write, data = %d",data_w)
        await RisingEdge(self.clk)
        await Timer (1, units='ns')      
        self.bus.rd_en.value = 0
        self.bus.wr_en.value = 0

class InputMonitor(BusMonitor):
    _signals = ["wr_en","rd_en","lifo_empty","lifo_full","data_rd","data_wr"]

    def __init__(self, dut, name, clk, reset):
        BusMonitor.__init__(self, dut, name, clk, reset)
        self.clk = clk
        self.reset = reset
        self.dut = dut

    async def _monitor_recv(self):
        global err_cnt
        lifo_expected = []
        rd_en_buf = 0
        wr_en_buf = 0
        data_wr_buf = 0
        while True:
             await RisingEdge(self.clock)
             await Timer(3,units='ns') 
             await ReadOnly()

             if self.reset.value == 1:
                 rd_en_buf = 0
                 wr_en_buf = 0
                 data_wr_buf = 0
                 continue

             if(rd_en_buf == 1 and wr_en_buf == 1):
                if(self.bus.data_rd.value == data_wr_buf):
                    self.dut._log.info("Monitor: Simultaneous Data read/write, ACT = %d, EXP = %d, FIFO entry = %d", self.bus.data_rd.value, data_wr_buf, len(lifo_expected))
             elif(wr_en_buf and len(lifo_expected) != DEPTH): 
                lifo_expected.append(data_wr_buf)
                self.dut._log.info("Monitor: Data write = %d, FIFO entry = %d", data_wr_buf, len(lifo_expected))
             elif(rd_en_buf == 1 and len(lifo_expected) != 0):
                lifo_expected.pop()
                self.dut._log.info("Monitor: Data read = %d, FIFO entry = %d", self.bus.data_rd.value, len(lifo_expected))

             if(len(lifo_expected) == 0):
                if(self.bus.lifo_empty.value):
                    self.dut._log.info("Monitor: LIFO is empty, lifo_full flag is asserted correctly")
                else:
                    self.dut._log.error("Monitor: LIFO is empty, but lifo_full flag is not asserted")
                    err_cnt += 1
             elif(self.bus.lifo_empty.value): 
                    self.dut._log.error("Monitor: LIFO is not empty, but lifo_empty flag is asserted")
             
             if(len(lifo_expected) == DEPTH):
                if(self.bus.lifo_full.value):
                    self.dut._log.info("Monitor: LIFO is full, lifo_full flag is asserted correctly")
                else:
                    self.dut._log.error("Monitor: LIFO is full, but lifo_full flag is not asserted")
                    err_cnt += 1
             elif(self.bus.lifo_full.value):
                self.dut._log.error("Monitor: LIFO is not full, but lifo_full flag is asserted")

             rd_en_buf = int(self.bus.rd_en.value)
             wr_en_buf = int(self.bus.wr_en.value)
             data_wr_buf = int(self.bus.data_wr.value)


async def dut_init(dut):
    global DEPTH 
    global DATA_WIDTH
    global MAX_DATA
    DEPTH = dut.DEPTH.value 
    DATA_WIDTH = dut.DATA_WIDTH.value
    MAX_DATA = 2**DATA_WIDTH - 1
    await cocotb.start(Clock(dut.clk, CLK_PERIOD, units="ns").start())
    dut.data_wr.value = 0
    dut.rd_en.value = 0
    dut.wr_en.value = 0
    dut.rst.value = 1
    await(Timer(100,'ns'))
    dut.rst.value = 0
    await(Timer(100,'ns'))
    

@cocotb.test()
async def lifo_rand_op_test(dut):
    await dut_init(dut)
    driver = OutputDriver(dut, None, dut.clk) #set name='None', refer to Bus class
    monitor = InputMonitor(dut, None, dut.clk, dut.rst)
    cocotb.log.info("SEED NUMBER = %d",cocotb.RANDOM_SEED)
    i = DEPTH
    lifo_expected = []
    while(i >= 0):
        op_sel = random.randint(0,1)
        op_count = random.randint(1,5)
        i = i - op_count      
        await driver._driver_send(op_sel,op_count)
        await Timer(CLK_PERIOD,'ns')
        if (err_cnt > 0):
            cocotb.log.error("Errors count = %d",err_cnt)
            cocotb.result.test_fail()
