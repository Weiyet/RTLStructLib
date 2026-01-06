"""Dual Edge FF VIP Driver"""
from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge
from ..common.deff_vip_seq_item import DeffVipSeqItem

class DeffVipDriver(uvm_driver):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "deff_vip_cfg")

    async def run_phase(self):
        self.dut = ConfigDB().get(self, "", "deff_vip_dut")
        self.dut.data_in.value = 0
        self.dut.pos_edge_latch_en.value = 0
        self.dut.neg_edge_latch_en.value = 0

        while True:
            item = await self.seq_item_port.get_next_item()
            await self.drive_item(item)
            self.seq_item_port.item_done()

    async def drive_item(self, item):
        await RisingEdge(self.dut.clk)
        self.dut.data_in.value = item.data_in
        self.dut.pos_edge_latch_en.value = item.pos_edge_latch_en
        self.dut.neg_edge_latch_en.value = item.neg_edge_latch_en

        # Wait for data to propagate through dual-edge FF
        await RisingEdge(self.dut.clk)
        item.data_out = int(self.dut.data_out.value)
