"""
List VIP Monitor
Create Date: 01/05/2026

Monitor for List VIP - observes DUT signals
"""

from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_types import ListOp
from ..common.list_vip_config import ListVipConfig


class ListVipMonitor(uvm_monitor):
    """Monitor for List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None
        self.ap = uvm_analysis_port("ap", self)

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "list_vip_cfg")
        if self.cfg is None:
            self.logger.error("No config object found")

    async def run_phase(self):
        await self.get_dut()

        while True:
            await RisingEdge(self.dut.clk)

            # Detect operation when op_en is asserted
            if self.dut.op_en.value:
                item = ListVipSeqItem("monitored_item")

                # Capture operation type
                op_sel = int(self.dut.op_sel.value)
                op_map = {
                    0b000: ListOp.READ,
                    0b001: ListOp.INSERT,
                    0b010: ListOp.FIND_ALL,
                    0b011: ListOp.FIND_1ST,
                    0b100: ListOp.SUM,
                    0b101: ListOp.SORT_ASC,
                    0b110: ListOp.SORT_DES,
                    0b111: ListOp.DELETE
                }
                item.op = op_map.get(op_sel, ListOp.IDLE)

                # Capture inputs
                item.data = int(self.dut.data_in.value)
                item.index = int(self.dut.index_in.value)

                # Wait for operation to complete
                await RisingEdge(self.dut.clk)
                while not self.dut.op_done.value:
                    await RisingEdge(self.dut.clk)

                # Capture outputs
                item.result_data = int(self.dut.data_out.value)
                item.op_done = bool(self.dut.op_done.value)
                item.op_error = bool(self.dut.op_error.value)
                item.current_len = int(self.dut.len.value)

                self.ap.write(item)
                self.logger.debug(f"Observed {item.op.name}: {item.convert2string()}")

    async def get_dut(self):
        """Get DUT handle from ConfigDB"""
        self.dut = ConfigDB().get(self, "", "list_vip_dut")
        if self.dut is None:
            self.logger.error("No DUT found in ConfigDB")
