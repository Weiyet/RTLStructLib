"""
Singly Linked List VIP Monitor
Create Date: 01/05/2026

Monitor for Singly Linked List VIP - observes DUT signals
"""

from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge
from ..common.sll_vip_seq_item import SllVipSeqItem
from ..common.sll_vip_types import SllOp
from ..common.sll_vip_config import SllVipConfig


class SllVipMonitor(uvm_monitor):
    """Monitor for Singly Linked List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None
        self.ap = uvm_analysis_port("ap", self)

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "sll_vip_cfg")
        if self.cfg is None:
            self.logger.error("No config object found")

    async def run_phase(self):
        await self.get_dut()

        while True:
            await RisingEdge(self.dut.clk)

            # Detect operation when op_start is asserted
            if self.dut.op_start.value:
                item = SllVipSeqItem("monitored_item")

                # Capture operation type
                op_val = int(self.dut.op.value)
                op_map = {
                    0: SllOp.READ_ADDR,
                    1: SllOp.INSERT_AT_ADDR,
                    2: SllOp.DELETE_VALUE,
                    3: SllOp.DELETE_AT_ADDR,
                    4: SllOp.IDLE,
                    5: SllOp.INSERT_AT_INDEX,
                    7: SllOp.DELETE_AT_INDEX
                }
                item.op = op_map.get(op_val, SllOp.IDLE)

                # Capture inputs
                item.data = int(self.dut.data_in.value)
                item.addr = int(self.dut.addr_in.value)

                # Wait for operation to complete
                await RisingEdge(self.dut.clk)
                while not self.dut.op_done.value:
                    await RisingEdge(self.dut.clk)

                # Capture outputs
                item.result_data = int(self.dut.data_out.value)
                item.result_next_addr = int(self.dut.next_node_addr.value)
                item.op_done = bool(self.dut.op_done.value)
                item.fault = bool(self.dut.fault.value)
                item.current_len = int(self.dut.length.value)
                item.current_head = int(self.dut.head.value)
                item.current_tail = int(self.dut.tail.value)

                self.ap.write(item)
                self.logger.debug(f"Observed {item.op.name}: {item.convert2string()}")

    async def get_dut(self):
        """Get DUT handle from ConfigDB"""
        self.dut = ConfigDB().get(self, "", "sll_vip_dut")
        if self.dut is None:
            self.logger.error("No DUT found in ConfigDB")
