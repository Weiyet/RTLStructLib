"""LIFO VIP Driver"""
from pyuvm import uvm_driver
from cocotb.triggers import RisingEdge
from ..common.lifo_vip_seq_item import LifoVipSeqItem
from ..common import LifoOp

class LifoVipDriver(uvm_driver):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        from pyuvm import ConfigDB
        arr = []
        if not ConfigDB().get(self, "", "lifo_vip_dut", arr):
            self.logger.critical("No DUT found in ConfigDB!")
        else:
            self.dut = arr[0]

        arr = []
        if not ConfigDB().get(self, "", "lifo_vip_cfg", arr):
            self.logger.critical("No config found in ConfigDB!")
        else:
            self.cfg = arr[0]

    async def run_phase(self):
        while True:
            item = await self.seq_item_port.get_next_item()
            await self.drive_item(item)
            self.seq_item_port.item_done()

    async def drive_item(self, item):
        """Drive transaction to DUT"""
        if item.op == LifoOp.PUSH:
            await self.drive_push(item)
        elif item.op == LifoOp.POP:
            await self.drive_pop(item)
        elif item.op == LifoOp.IDLE:
            await self.drive_idle()

    async def drive_push(self, item):
        """Drive PUSH operation"""
        await RisingEdge(self.dut.clk)
        self.dut.wr_en.value = 1
        self.dut.rd_en.value = 0
        data_mask = (1 << self.cfg.DATA_WIDTH) - 1
        self.dut.data_wr.value = item.data & data_mask

        await RisingEdge(self.dut.clk)
        item.full = bool(self.dut.lifo_full.value)
        item.success = not item.full

        self.dut.wr_en.value = 0

        self.logger.debug(f"PUSH: data=0x{item.data:x} full={item.full}")

    async def drive_pop(self, item):
        """Drive POP operation"""
        await RisingEdge(self.dut.clk)
        self.dut.rd_en.value = 1
        self.dut.wr_en.value = 0

        await RisingEdge(self.dut.clk)
        item.empty = bool(self.dut.lifo_empty.value)
        item.read_data = int(self.dut.data_rd.value)
        item.success = not item.empty

        self.dut.rd_en.value = 0

        self.logger.debug(f"POP: data=0x{item.read_data:x} empty={item.empty}")

    async def drive_idle(self):
        """Drive IDLE cycle"""
        await RisingEdge(self.dut.clk)
        self.dut.wr_en.value = 0
        self.dut.rd_en.value = 0
