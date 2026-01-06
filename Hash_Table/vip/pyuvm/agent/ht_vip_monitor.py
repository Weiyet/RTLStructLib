"""Hash Table VIP Monitor"""
from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge
from ..common.ht_vip_seq_item import HtVipSeqItem
from ..common.ht_vip_types import HtOp

class HtVipMonitor(uvm_monitor):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        self.dut = ConfigDB().get(self, "", "ht_vip_dut")
        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.op_en.value:
                item = HtVipSeqItem("mon")
                op_map = {0: HtOp.INSERT, 1: HtOp.DELETE, 2: HtOp.SEARCH, 3: HtOp.IDLE}
                item.op = op_map.get(int(self.dut.op_sel.value), HtOp.IDLE)
                item.key = int(self.dut.key_in.value)
                item.value = int(self.dut.value_in.value)

                await RisingEdge(self.dut.clk)
                while not self.dut.op_done.value:
                    await RisingEdge(self.dut.clk)

                item.result_value = int(self.dut.value_out.value)
                item.op_done = bool(self.dut.op_done.value)
                item.op_error = bool(self.dut.op_error.value)
                item.collision_count = int(self.dut.collision_count.value)
                self.ap.write(item)
