"""Dual Edge FF VIP Monitor"""
from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge
from ..common.deff_vip_seq_item import DeffVipSeqItem

class DeffVipMonitor(uvm_monitor):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        self.dut = ConfigDB().get(self, "", "deff_vip_dut")
        while True:
            await RisingEdge(self.dut.clk)

            # Capture transaction
            if (int(self.dut.pos_edge_latch_en.value) | int(self.dut.neg_edge_latch_en.value)) != 0:
                item = DeffVipSeqItem("mon")
                item.data_in = int(self.dut.data_in.value)
                item.pos_edge_latch_en = int(self.dut.pos_edge_latch_en.value)
                item.neg_edge_latch_en = int(self.dut.neg_edge_latch_en.value)

                await RisingEdge(self.dut.clk)
                item.data_out = int(self.dut.data_out.value)
                self.ap.write(item)
