"""
Singly Linked List VIP Driver
Create Date: 01/05/2026

Driver for Singly Linked List VIP - drives transactions to DUT
"""

from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge
from ..common.sll_vip_seq_item import SllVipSeqItem
from ..common.sll_vip_types import SllOp
from ..common.sll_vip_config import SllVipConfig


class SllVipDriver(uvm_driver):
    """Driver for Singly Linked List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "sll_vip_cfg")
        if self.cfg is None:
            self.logger.error("No config object found")

    async def run_phase(self):
        await self.get_dut()

        # Initialize signals
        self.dut.op.value = 0
        self.dut.op_start.value = 0
        self.dut.data_in.value = 0
        self.dut.addr_in.value = 0

        while True:
            item = await self.seq_item_port.get_next_item()
            await self.drive_item(item)
            self.seq_item_port.item_done()

    async def get_dut(self):
        """Get DUT handle from ConfigDB"""
        self.dut = ConfigDB().get(self, "", "sll_vip_dut")
        if self.dut is None:
            self.logger.error("No DUT found in ConfigDB")

    async def drive_item(self, item):
        """Drive transaction to DUT"""
        await RisingEdge(self.dut.clk)

        # Set operation and inputs
        self.dut.op.value = item.op.value
        self.dut.op_start.value = 1

        # Mask data and address based on config
        data_mask = (1 << self.cfg.DATA_WIDTH) - 1
        self.dut.data_in.value = item.data & data_mask
        self.dut.addr_in.value = item.addr

        await RisingEdge(self.dut.clk)
        # Wait for operation to complete
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

        await RisingEdge(self.dut.clk)
        self.dut.op_start.value = 0

        self.logger.debug(f"{item.op.name}: addr={item.addr} data=0x{item.data:x} fault={item.fault}")
