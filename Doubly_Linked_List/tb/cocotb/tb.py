import random
#import asyncio
import math
import cocotb
import cocotb.result
from cocotb.triggers import Timer, RisingEdge, ReadOnly
from cocotb.clock import Clock
from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor
from cocotb.binary import BinaryValue

#BIN string
#BinaryValue(dut.data_wr.value, n_bits=8) ; BinaryValue.integar ; BinaryValue.hex ; BinaryValue.binstr; BinaryValue.signed_integer ; can represent x,z

DATA_WIDTH = 8 # DUT paramter
MAX_NODE = 8 # DUT paramter

ADDR_NULL = MAX_NODE + 1
MAX_DATA  = 2**DATA_WIDTH - 1

OP_Read = 0b000
OP_Insert_At_Addr = 0b001
OP_Insert_At_Index = 0b101
OP_Delete_Value = 0b010
OP_Delete_At_Addr = 0b011
OP_Delete_At_Index = 0b111;

TB_CLK_PERIOD = 30 # TB clk generator
TB_SIM_TIMEOUT = 30 # TB sim timeout 30ms
TB_TEST_WEIGHT = 1
err_cnt = 0

# doubly_linked_list #(.DATA_WIDTH(DUT_DATA_WIDTH),.MAX_NODE(DUT_MAX_NODE)) DUT
# (   /*input*/  .rst(rst),
#     /*input*/  .clk(clk),
#     /*input [DATA_WIDTH-1:0]*/ .data_in(data_in), 
#     /*input [ADDR_WIDTH-1:0]*/ .addr_in(addr_in),
#     /*input [1:0]*/ .op(op), // 0: Read(addr_in); 1: Delete_Value(data_in); 2: Push_Back(data_in); 3: Push_front(data_in)
#     /*input*/  .op_start(op_start), 
#     /*output reg [DATA_WIDTH-1:0]*/ .data_out(data_out),
#     /*output reg*/  .op_done(op_done),
#     /*output wire [ADDR_WIDTH-1:0]*/ .pre_node_addr(pre_node_addr),// Addr of pre node
#     /*output wire [ADDR_WIDTH-1:0]*/ .next_node_addr(next_node_addr), // Addr of next node
#     // status 
#     /*output reg [ADDR_WIDTH-1:0]*/  .length(length), 
#     /*output wire*/ .full(full), 
#     /*output reg [ADDR_WIDTH-1:0]*/ .head(head), // Addr of head
#     /*output reg [ADDR_WIDTH-1:0]*/ .tail(tail), // Addr of head
#     /*output wire*/ .empty(empty),
#     /*output reg*/  .fault(fault) // Invalid Errors 
# );

# Actual Python linked_list class: https://www.datacamp.com/tutorial/python-linked-lists
# To mimic harware linked_list, we need to keep track of the address of each node, model in below way also for our ease of debug. 
class doubly_linked_list:
    def __init__(self, dut):
        self.dut = dut
        self.linked_list_value = []
        self.linked_list_addr = []

    def remove(self, index):
        self.linked_list_value.pop(index)
        self.linked_list_addr.pop(index)

    def find_next_addr(self):
        for i in range(len(self.linked_list_addr)+2):
            if i not in self.linked_list_addr:
                return i

    def insert_by_addr(self, addr, data):
        if(addr == -1):
            self.linked_list_value.append(data)
            self.linked_list_addr.append(self.find_next_addr())
        else:
            self.linked_list_value.insert(self.linked_list_addr.index(addr), data)
            self.linked_list_addr.insert(self.linked_list_addr.index(addr), self.find_next_addr())

    def insert_by_index(self, index, data):
        if(index == -1):
            self.linked_list_value.append(data)
            self.linked_list_addr.append(self.find_next_addr())
        else:
            self.linked_list_value.insert(index, data)
            self.linked_list_addr.insert(index, self.find_next_addr())

    def delete_by_value(self, data):
        self.linked_list_addr.remove(self.linked_list_value.index(data))
        self.linked_list_value.remove(data)
        
    def delete_by_addr(self, addr):
        self.linked_list_value.pop(self.linked_list_addr.index(addr))
        self.linked_list_addr.pop(self.linked_list_addr.index(addr))

    def read_by_addr(self, addr):
        return self.linked_list_value[self.linked_list_addr.index(addr)]

    def print_content(self):
        cocotb.log.info(f"Linked List Content: value = {self.linked_list_value}, addr = {self.linked_list_addr}")

async def read_n_front(dut, list_exp, n):
    global err_cnt
    cocotb.log.info("OP_Read %0d values", n)
    i = 0
    await RisingEdge(dut.clk)
    await Timer (1, units = 'ns')
    dut.op.value = OP_Read
    dut.op_start.value = 1
    dut.addr_in.value = dut.head.value
    i = i + 1
    while (i <= n):
        await RisingEdge(dut.clk)
        await Timer (1, units = 'ns')
        if (dut.op_done.value == 1):
            if( (i-1) >= len(list_exp.linked_list_addr)):
                if(dut.fault.value == 1):
                    cocotb.log.info("Data read out of bound, fault flag is asserted correctly")
                else:
                    cocotb.log.error("Data read out of bound, fault flag is not asserted")
                    err_cnt += 1
            elif (list_exp.linked_list_value[i-1] == dut.data_out.value):
                cocotb.log.info("Data read : %0d at Index %0d", dut.data_out.value, i-1)
            else:
                cocotb.log.error("Data read at Index %0d is Correct, ACT: %0d, EXP: %0d", i-1, dut.data_out.value, list_exp.linked_list_value[i-1])
                err_cnt += 1
            if(i==n):
                dut.op_start.value = 0
            dut.addr_in.value = dut.next_node_addr.value
            i = i + 1
    list_exp.print_content()

async def read_n_back(dut, list_exp, n):
    global err_cnt
    cocotb.log.info("OP_Read %0d values", n)
    i = 0
    await RisingEdge(dut.clk)
    await Timer (1, units = 'ns')
    dut.op.value = OP_Read
    dut.op_start.value = 1
    dut.addr_in.value = dut.tail.value
    i = i + 1
    while (i <= n):
        await RisingEdge(dut.clk)
        await Timer (1, units = 'ns')
        if (dut.op_done.value == 1):
            if( (i-1) >= len(list_exp.linked_list_addr)):
                if(dut.fault.value == 1):
                    cocotb.log.info("Data read out of bound, fault flag is asserted correctly")
                else:
                    cocotb.log.error("Data read out of bound, fault flag is not asserted")
                    err_cnt += 1
            elif (list_exp.linked_list_value[-i] == dut.data_out.value):
                cocotb.log.info("Data read : %0d at Index %0d", dut.data_out.value, len(list_exp.linked_list_addr)-1-(i-1))
            else:
                cocotb.log.error("Data read at Index %0d is Correct, ACT: %0d, EXP: %0d", i-1, dut.data_out.value, list_exp.linked_list_value[-i])
                err_cnt += 1
            if(i==n):
                dut.op_start.value = 0
            dut.addr_in.value = dut.pre_node_addr.value
            i = i + 1
    list_exp.print_content()

async def delete_value(dut, list_exp, value):
     global err_cnt
     cocotb.log.info("OP_Delete_Value %0d value", value)
     i = 0
     found = 0
     await RisingEdge(dut.clk)
     await Timer (1, units = 'ns')
     dut.op.value = OP_Delete_Value
     dut.data_in.value = value
     dut.op_start.value = 1
     await RisingEdge(dut.op_done)
     await Timer (1, units = 'ns')
     for i in range(len(list_exp.linked_list_addr)):
         if list_exp.linked_list_value[i] == value:
             cocotb.log.info("Data %0d at Index %0d is Deleted_by_Value", value, i)
             list_exp.remove(i)
             found = 1
             break
     if found == 0:
         if(dut.fault.value == 1):
             cocotb.log.info("Data delete out of bound, fault flag is asserted correctly")
         else:
             cocotb.log.error("Data delete out of bound, fault flag is not asserted")
             err_cnt += 1
     else:
         if(dut.fault.value == 1):
             cocotb.log.error("Data delete in bound, fault flag is asserted incorrectly")
             err_cnt += 1 
     dut.op_start.value = 0 
     list_exp.print_content()

async def delete_at_index(dut, list_exp, index):
    global err_cnt
    cocotb.log.info("OP_Delete_At_Index %0d index", index)
    await RisingEdge(dut.clk)
    await Timer (1, units = 'ns')
    dut.op.value = OP_Delete_At_Index
    dut.addr_in.value = index
    dut.op_start.value = 1
    await RisingEdge(dut.op_done)
    await Timer (1, units = 'ns')
    if (index >= len(list_exp.linked_list_addr)):
        if(dut.fault.value == 1):
            cocotb.log.info("Data delete out of bound, fault flag is asserted correctly")
        else:
            cocotb.log.error("Data delete out of bound, fault flag is not asserted")
            err_cnt += 1
    elif (index == 0):
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        cocotb.log.info("Data %0d at Front is Deleted_by_Index", list_exp.linked_list_value[0])
        list_exp.remove(0)
    else:
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        cocotb.log.info("Data %0d at Index %0d is Deleted_by_Index", list_exp.linked_list_value[index], index)
        list_exp.remove(index)
    dut.op_start.value = 0
    list_exp.print_content()

async def insert_at_index(dut, list_exp, index, data):
    global err_cnt
    cocotb.log.info("OP_Insert_At_Index %0d index, %0d data", index, data)
    await RisingEdge(dut.clk)
    await Timer (1, units = 'ns')
    dut.op.value = OP_Insert_At_Index
    dut.addr_in.value = index
    dut.data_in.value = data
    dut.op_start.value = 1
    await RisingEdge(dut.op_done)
    await Timer (1, units = 'ns')
    if (len(list_exp.linked_list_value) >= MAX_NODE):
        if(dut.fault.value == 1):
            cocotb.log.info("Data insert out of bound, fault flag is asserted correctly")
        else:
            cocotb.log.error("Data insert out of bound, fault flag is not asserted")
            err_cnt += 1
    elif (index == 0):
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        list_exp.insert_by_index(0, data)
        cocotb.log.info("Data %0d at Front is Inserted_by_Index", data)
    elif (index >= len(list_exp.linked_list_value)):
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        list_exp.insert_by_index(-1, data)
        cocotb.log.info("Data %0d at End is Inserted_by_Index", data)
    else:
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        list_exp.insert_by_index(index, data)
        cocotb.log.info("Data %0d at Index %0d is Inserted_by_Index", data, index)
    if(len(list_exp.linked_list_value) >= MAX_NODE):
        if(dut.full.value == 1):
            cocotb.log.info("Full flag is asserted correctly")
        else:
            cocotb.log.error("Full flag is not asserted")
            err_cnt += 1
    elif (dut.full.value == 1):
        cocotb.log.error("Full flag is asserted incorrectly")
        err_cnt += 1
    dut.op_start.value = 0
    list_exp.print_content()

async def delete_at_addr (dut, list_exp, addr):
    global err_cnt
    cocotb.log.info("OP_Delete_At_Addr %0d addr", addr)
    await RisingEdge(dut.clk)
    await Timer (1, units = 'ns')
    dut.op.value = OP_Delete_At_Addr
    dut.addr_in.value = addr
    dut.op_start.value = 1
    pre_head = int(dut.head.value)
    pre_tail = int(dut.tail.value)

    await RisingEdge(dut.op_done)
    await Timer (1, units = 'ns')
    if (addr >= ADDR_NULL):
        if(dut.fault.value == 1):
            cocotb.log.info("Data delete out of bound, fault flag is asserted correctly")
        else:
            cocotb.log.error("Data delete out of bound, fault flag is not asserted")
            err_cnt += 1
    elif (addr == pre_head):
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        cocotb.log.info("Data %0d at Front is Deleted_by_Addr", list_exp.linked_list_value[0])
        list_exp.remove(0)
    elif (addr == pre_tail):
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        cocotb.log.info("Data %0d at Back is Deleted_by_Addr", list_exp.linked_list_value[0])
        list_exp.remove(-1)
    else:
        if(addr not in list_exp.linked_list_addr):
            if(dut.fault.value == 0):
                cocotb.log.error("Fault flag is not asserted")
                err_cnt += 1
        else:
            if(dut.fault.value == 1):
                cocotb.log.error("Fault flag is asserted incorrectly")
                err_cnt += 1
            cocotb.log.info("Data %0d at Addr %0d is Inserted_by_Addr", list_exp.linked_list_value[list_exp.linked_list_addr.index(addr)], addr)
            list_exp.delete_by_addr(addr)
    if(len(list_exp.linked_list_value) == 0):
        if(dut.empty.value == 1):
            cocotb.log.info("Full flag is asserted correctly")
        else:
            cocotb.log.error("Full flag is not asserted")
            err_cnt += 1
    elif (dut.empty.value == 1):
        cocotb.log.error("Full flag is asserted incorrectly")
        err_cnt += 1
    dut.op_start.value = 0
    list_exp.print_content()

async def insert_at_addr(dut, list_exp, addr, data):
    global err_cnt
    cocotb.log.info("OP_Insert_At_Addr %0d addr, %0d data", addr, data)
    await RisingEdge(dut.clk)
    await Timer (1, units = 'ns')
    dut.op.value = OP_Insert_At_Addr
    dut.addr_in.value = addr
    dut.data_in.value = data
    dut.op_start.value = 1
    pre_head = int(dut.head.value)
    pre_tail = int(dut.tail.value)

    await RisingEdge(dut.op_done)
    await Timer (1, units = 'ns')
    if (len(list_exp.linked_list_value) >= MAX_NODE):
        if(dut.fault.value == 1):
            cocotb.log.info("Data insert out of bound, fault flag is asserted correctly")
        else:
            cocotb.log.error("Data insert out of bound, fault flag is not asserted")
            err_cnt += 1
    elif (addr >= ADDR_NULL):
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        list_exp.insert_by_addr(-1, data)
        cocotb.log.info("Data %0d at End is Inserted_by_Addr", data)
    elif (addr == pre_head):
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        list_exp.insert_by_addr(addr, data)
        cocotb.log.info("Data %0d at Front is Inserted_by_Addr", data)
    elif (addr == pre_tail):
        if(dut.fault.value == 1):
            cocotb.log.error("Fault flag is asserted incorrectly")
            err_cnt += 1
        list_exp.insert_by_index(len(list_exp.linked_list_value)-1, data)
        cocotb.log.info("Data %0d at End is Inserted_by_Addr", data)
    else:
        if(addr not in list_exp.linked_list_addr):
            if(dut.fault.value == 0):
                cocotb.log.error("Fault flag is not asserted")
                err_cnt += 1
        else:
            if(dut.fault.value == 1):
                cocotb.log.error("Fault flag is asserted incorrectly")
                err_cnt += 1
            list_exp.insert_by_addr(addr, data)
            cocotb.log.info("Data %0d at Addr %0d is Inserted_by_Addr", data, addr)
    if(len(list_exp.linked_list_value) >= MAX_NODE):
        if(dut.full.value == 1):
            cocotb.log.info("Full flag is asserted correctly")
        else:
            cocotb.log.error("Full flag is not asserted")
            err_cnt += 1
    elif (dut.full.value == 1):
        cocotb.log.error("Full flag is asserted incorrectly")
        err_cnt += 1
    dut.op_start.value = 0
    list_exp.print_content()

async def dut_init(dut):
    global DATA_WIDTH # DUT paramter
    global MAX_NODE # DUT paramter
    global ADDR_NULL
    global MAX_DATA 
    DATA_WIDTH = dut.DATA_WIDTH.value
    MAX_NODE = dut.MAX_NODE.value
    ADDR_NULL = MAX_NODE
    MAX_DATA  = 2**DATA_WIDTH - 1
    await cocotb.start(Clock(dut.clk, TB_CLK_PERIOD, units="ns").start())
    dut.data_in.value = 0
    dut.addr_in.value = 0
    dut.op.value = 0
    dut.op_start.value = 0
    dut.rst.value = 1
    await(Timer(100,'ns'))
    dut.rst.value = 0
    await(Timer(100,'ns'))

@cocotb.test()
async def index_op_test(dut):
    await dut_init(dut)
    list_exp = doubly_linked_list(dut)
    cocotb.log.info("SEED NUMBER = %d",cocotb.RANDOM_SEED)
    await insert_at_index(dut,list_exp,0,3)
    await insert_at_index(dut,list_exp,0,0)
    await Timer(200, units = 'ns')
    await insert_at_index(dut,list_exp,4,5)
    await insert_at_index(dut,list_exp,0,6)
    await insert_at_index(dut,list_exp,0,7)  
    await insert_at_index(dut,list_exp,1,3)
    await insert_at_index(dut,list_exp,2,4)
    await insert_at_index(dut,list_exp,ADDR_NULL,3)
    await insert_at_index(dut,list_exp,ADDR_NULL,4)
    await insert_at_index(dut,list_exp,ADDR_NULL,1)
    await insert_at_index(dut,list_exp,0,3)
    await Timer(200, units = 'ns')
    await read_n_front(dut,list_exp,len(list_exp.linked_list_value))
    await read_n_back(dut,list_exp,len(list_exp.linked_list_value))
    await Timer(200, units = 'ns')
    await delete_value(dut,list_exp,7)
    await delete_at_index(dut,list_exp,0)
    await delete_at_index(dut,list_exp,0)
    await delete_value(dut,list_exp,2)
    await delete_value(dut,list_exp,4)
    await delete_at_index(dut,list_exp,0)
    await delete_at_index(dut,list_exp,7)
    await delete_at_index(dut,list_exp,dut.length.value-1)
    await delete_at_index(dut,list_exp,dut.length.value-1)
    await delete_at_index(dut,list_exp,0)    
    await delete_at_index(dut,list_exp,0)
    await delete_at_index(dut,list_exp,0)    
    await Timer(200, units = 'ns')

    if (err_cnt > 0):
        cocotb.log.error("Errors count = %d",err_cnt)
        cocotb.result.TestFailure() #FIX ME

@cocotb.test()
async def addr_op_test(dut):
    await dut_init(dut)
    list_exp = doubly_linked_list(dut)
    cocotb.log.info("SEED NUMBER = %d",cocotb.RANDOM_SEED)
    await insert_at_addr(dut, list_exp, int(dut.head.value), 3)
    await insert_at_addr(dut, list_exp, int(dut.head.value), 0)
    await Timer(100, units='ns')
    await insert_at_addr(dut, list_exp, int(dut.head.value), 5)
    await insert_at_addr(dut, list_exp, int(dut.head.value), 6)
    await insert_at_addr(dut, list_exp, list_exp.linked_list_addr[2], 7)
    await insert_at_addr(dut, list_exp, 0, 3)
    await insert_at_addr(dut, list_exp, int(dut.head.value), 4)
    await insert_at_addr(dut, list_exp, int(dut.tail.value), 3)
    await insert_at_addr(dut, list_exp, ADDR_NULL, 4)
    await insert_at_addr(dut, list_exp, ADDR_NULL, 1)
    await insert_at_addr(dut, list_exp, 0, 3)
    await Timer(200, units='ns')
    await read_n_front(dut, list_exp, len(list_exp.linked_list_value))
    await read_n_back(dut, list_exp, len(list_exp.linked_list_value))
    await Timer(500, units='ns')
    await delete_value(dut, list_exp, 7)
    await delete_at_addr(dut, list_exp, 0)
    await delete_at_addr(dut, list_exp, 0)
    await delete_value(dut, list_exp, 2)
    await read_n_front(dut, list_exp, len(list_exp.linked_list_value))
    await delete_value(dut, list_exp, 4)
    await delete_at_addr(dut, list_exp, 0)
    await delete_at_addr(dut, list_exp, 7)
    await delete_at_addr(dut, list_exp, int(dut.head.value))
    await delete_at_addr(dut, list_exp, int(dut.tail.value)-1)
    await delete_at_addr(dut, list_exp, 0)
    await Timer(500, units='ns')

    if (err_cnt > 0):
        cocotb.log.error("Errors count = %d",err_cnt)
        cocotb.result.TestError() #FIX ME 
