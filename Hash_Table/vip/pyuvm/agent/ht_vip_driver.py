"""Hash Table VIP Driver"""
from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge
from ..common.ht_vip_seq_item import HtVipSeqItem
from ..common.ht_vip_types import HtOp

class HtVipDriver(uvm_driver):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "ht_vip_cfg")

    async def run_phase(self):
        self.dut = ConfigDB().get(self, "", "ht_vip_dut")
        self.dut.op_sel.value = 3
        self.dut.op_en.value = 0
        self.dut.key_in.value = 0
        self.dut.value_in.value = 0

        while True:
            item = await self.seq_item_port.get_next_item()
            await self.drive_item(item)
            self.seq_item_port.item_done()

    async def drive_item(self, item):
        await RisingEdge(self.dut.clk)
        self.dut.op_sel.value = item.op.value
        self.dut.op_en.value = 1
        self.dut.key_in.value = item.key
        self.dut.value_in.value = item.value

        await RisingEdge(self.dut.clk)
        self.dut.op_en.value = 0

        while not self.dut.op_done.value:
            await RisingEdge(self.dut.clk)

        item.result_value = int(self.dut.value_out.value)
        item.op_done = bool(self.dut.op_done.value)
        item.op_error = bool(self.dut.op_error.value)
        item.collision_count = int(self.dut.collision_count.value)

        await RisingEdge(self.dut.clk)
