import random
#import asyncio
import math
import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly
from cocotb.clock import Clock
from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor
from cocotb.binary import BinaryValue

#BIN string
#BinaryValue(dut.data_wr.value, n_bits=8) ; BinaryValue.integar ; BinaryValue.hex ; BinaryValue.binstr; BinaryValue.signed_integer ; can represent x,z

TABLE_SIZE = 32 # DUT parameter
DATA_WIDTH = 8 # DUT paramter
INPUT_RATE = 1 # DUT parameter
OUTPUT_RATE = 1 # DUT parameter
INDEX_WIDTH = 1
TB_CLK_PERIOD = 30 # TB clk generator
TB_SIM_TIMEOUT = 30 # TB sim timeout 30ms
TB_TEST_WEIGHT = 1
table_expected = [0 for i in range(TABLE_SIZE)]
err_cnt = 0

# table_top #(
#     .TABLE_SIZE(TABLE_SIZE), 
#     .DATA_WIDTH(DATA_WIDTH),
#     .INPUT_RATE(INPUT_RATE), 
#     .OUTPUT_RATE(OUTPUT_RATE)) DUT (
#         /*input wire*/ .clk(clk),
#         /*input wire*/ .rst(rst), 
#         /*input wire*/ .wr_en(wr_en),
#         /*input wire*/ .rd_en(rd_en),
#         /*input wire [INPUT_RATE*$clog2(TABLE_SIZE)-1:0]*/ .index_wr(index_wr),
#         /*input wire [OUTPUT_RATE*$clog2(TABLE_SIZE)-1:0]*/ .index_rd(index_rd),
#         /*input wire [INPUT_RATE*DATA_WIDTH-1:0]*/ .data_wr(data_wr),
#         /*output reg [OUTPUT_RATE*DATA_WIDTH-1:0]*/ .data_rd(data_rd));

class OutputDriver(BusDriver):
    _signals = ["wr_en", "rd_en", "index_wr", "index_rd", "data_wr"] #dut.wr_en ; dut.rd_en; dut.index_wr; dut.data_wr

    def __init__(self, dut, name, clk):
        BusDriver.__init__(self, dut, name, clk)
        self.bus.wr_en.value = 0
        self.bus.rd_en.value = 0
        self.bus.index_wr.value = 0
        self.bus.index_rd.value = 0
        self.bus.data_wr.value = 0
        self.dut = dut
        self.clk = clk

    # async def _driver_send(self):
    async def write_burst(self, input_data):
        for i in range(0,len(input_data)//INPUT_RATE): 
            await RisingEdge(self.clk)
            await Timer (1, units = 'ns')
            data_wr = 0
            index_wr = 0
            for j in range(0,INPUT_RATE):
                data_wr = (data_wr<<(j)*DATA_WIDTH) + input_data[i*INPUT_RATE+j][1] 
                index_wr = (index_wr<<(j)*INDEX_WIDTH) + input_data[i*INPUT_RATE+j][0] 
            self.bus.wr_en.value = 2**INPUT_RATE - 1
            self.bus.data_wr.value = data_wr
            self.bus.index_wr.value = index_wr      
        await RisingEdge(self.clk)
        await Timer (1, units = 'ns')               
        self.bus.wr_en.value = 0

    async def read_burst(self, target_index): 
        for i in range(0,len(target_index)//OUTPUT_RATE):  
            await RisingEdge(self.clk)
            await Timer (1, units = 'ns')
            index_rd = 0
            for j in range(0,OUTPUT_RATE):
                index_rd = (index_rd<<(j)*INDEX_WIDTH) + target_index[i*OUTPUT_RATE+j]
            #print(index_rd)
            self.bus.rd_en.value = 1
            self.bus.index_rd.value = index_rd      
        await RisingEdge(self.clk)
        await Timer (1, units = 'ns')               
        self.bus.rd_en.value = 0       

class InputMonitor(BusMonitor):
    _signals = ["wr_en","rd_en","index_wr","index_rd","data_wr","data_rd"]

    def __init__(self, dut, name, clk, reset):
        BusMonitor.__init__(self, dut, name, clk, reset)
        self.clk = clk
        self.reset = reset
        self.dut = dut

    async def _monitor_recv(self): #this will be called in init. 
        global err_cnt
        global table_expected
        while True:
             await RisingEdge(self.clock)
             await ReadOnly()
             #await Timer (1, units = 'ns')

             if self.reset.value == 1:
                 self.bus.wr_en.value = 0
                 self.bus.rd_en.value = 0
                 self.bus.index_wr.value = 0
                 self.bus.index_rd.value = 0
                 self.bus.data_wr.value = 0
                 table_expected = [0 for i in range(TABLE_SIZE)]
                 continue

             if self.bus.wr_en.value == (2**INPUT_RATE -1) and self.bus.rd_en.value == 1: 
                    self.read_update()
                    self.write_update()
             elif self.bus.wr_en.value == (2**INPUT_RATE - 1):
                    self.write_update()
             elif self.bus.rd_en.value == 1:
                    self.read_update()

    def write_update(self):
        global table_expected
        for j in range(0,INPUT_RATE):
            target_index = self.bus.index_wr.value & ((2**INDEX_WIDTH - 1) << (INDEX_WIDTH*j))
            target_index = target_index >> (INDEX_WIDTH*j)
            exp_data_wr = self.bus.data_wr.value & ((2**DATA_WIDTH - 1) << (DATA_WIDTH*j))
            exp_data_wr = exp_data_wr >> (DATA_WIDTH*j)
            table_expected[target_index] = exp_data_wr
            cocotb.log.info("WRITE OPERATION: INDEX = d%0d, DATA = d%0d", target_index, exp_data_wr)

    def read_update(self): 
        global err_cnt
        for j in range(0,OUTPUT_RATE):
            target_index = self.bus.index_rd.value & ((2**INDEX_WIDTH - 1) << (INDEX_WIDTH*j))
            target_index = target_index >> (INDEX_WIDTH*j)
            act_data_rd = self.bus.data_rd.value & ((2**DATA_WIDTH - 1) << (DATA_WIDTH*j))
            act_data_rd = act_data_rd >> (DATA_WIDTH*j)
            exp_data_rd = table_expected[target_index]
            if (act_data_rd == exp_data_rd):
                cocotb.log.info("READ  OPERATION: INDEX = d%0d, DATA = d%0d", target_index,act_data_rd)
            else:
                err_cnt += 1
                cocotb.log.error("READ  OPERATION: INDEX = d%0d, ACT DATA = d%0d, EXP DATA = d%0d, ", target_index, act_data_rd, exp_data_rd)

async def dut_init(dut):
    global TABLE_SIZE  # DUT parameter
    global DATA_WIDTH  # DUT paramter
    global INPUT_RATE  # DUT parameter
    global OUTPUT_RATE  # DUT parameter
    global INDEX_WIDTH
    TABLE_SIZE = dut.TABLE_SIZE.value
    DATA_WIDTH = dut.DATA_WIDTH.value
    INPUT_RATE = dut.INPUT_RATE.value
    OUTPUT_RATE = dut.OUTPUT_RATE.value
    INDEX_WIDTH = math.ceil(math.log2(TABLE_SIZE));
    await cocotb.start(Clock(dut.clk, TB_CLK_PERIOD, units="ns").start())
    dut.data_wr.value = 0
    dut.index_wr.value = 0
    dut.index_rd.value = 0
    dut.rd_en.value = 0
    dut.wr_en.value = 0
    dut.rst.value = 1
    await(Timer(100,'ns'))
    dut.rst.value = 0
    await(Timer(100,'ns'))
    

@cocotb.test()
async def table_rand_test(dut):
    await dut_init(dut)
    driver = OutputDriver(dut, None, dut.clk) #set name='None', refer to Bus class
    monitor = InputMonitor(dut, None, dut.clk, dut.rst)
    cocotb.log.info("SEED NUMBER = %d",cocotb.RANDOM_SEED)
    input_data = []
    read_index = []
   
    for j in range(TB_TEST_WEIGHT):
        for i in range(30):
            #data_wr = cocotb.binary.BinaryValue(n_bits=INPUT_RATE*DATA_WIDTH)
            #index_wr = cocotb.binary.BinaryValue(n_bits=INDEX_WIDTH)
            data_wr = 0
            index_wr = 0
            for k in range(0,INPUT_RATE):
                #data_wr = (data_wr<<(k-1)*DATA_WIDTH) + random.randint(0, 2**DATA_WIDTH-1)
                data_wr = random.randint(0, 2**DATA_WIDTH-1)
                #index_wr = (index_wr<<(k-1)*INDEX_WIDTH) + random.randint(0, TABLE_SIZE-1)
                index_wr = random.randint(0, TABLE_SIZE-1)
                input_data.append([index_wr,data_wr]) 
                read_index.append(index_wr)
    await driver.write_burst(input_data)
    await Timer (500, units = 'ns')
    await driver.read_burst(read_index)
    await Timer (500, units = 'ns') 
    
    if (err_cnt > 0):
        cocotb.log.error("Errors count = %d",err_cnt)
        cocotb.result.test_fail()
