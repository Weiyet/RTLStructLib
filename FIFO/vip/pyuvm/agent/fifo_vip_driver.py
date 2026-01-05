"""
FIFO VIP Driver
Create Date: 01/05/2026
"""

from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge, FallingEdge
from ..common.fifo_vip_types import FifoOp


class FifoVipDriver(uvm_driver):
    """Driver for FIFO transactions"""

    def __init__(self, name, parent, driver_type="WR"):
        super().__init__(name, parent)
        self.driver_type = driver_type  # "WR" or "RD"
        self.dut = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        # Get DUT handle
        self.dut = cocotb.top
        # Get config
        self.cfg = ConfigDB().get(self, "", "fifo_vip_cfg")
        if self.cfg is None:
            self.logger.critical("No config found")

    async def run_phase(self):
        """Main driver run phase"""
        # Initialize signals
        if self.driver_type == "WR":
            self.dut.wr_en.value = 0
            self.dut.data_wr.value = 0
            # Wait for reset
            await FallingEdge(self.dut.rst)
            await RisingEdge(self.dut.wr_clk)
        else:  # RD
            self.dut.rd_en.value = 0
            # Wait for reset
            await FallingEdge(self.dut.rst)
            await RisingEdge(self.dut.rd_clk)

        # Main loop
        while True:
            item = await self.seq_item_port.get_next_item()
            await self.drive_item(item)
            self.seq_item_port.item_done()

    async def drive_item(self, item):
        """Drive a single transaction"""
        # Set config on item
        item.set_config(self.cfg)

        if item.op == FifoOp.WRITE and self.driver_type == "WR":
            await self.drive_write(item)
        elif item.op == FifoOp.READ and self.driver_type == "RD":
            await self.drive_read(item)
        elif item.op == FifoOp.IDLE:
            # Just wait 2 clocks
            if self.driver_type == "WR":
                await RisingEdge(self.dut.wr_clk)
                await RisingEdge(self.dut.wr_clk)
            else:
                await RisingEdge(self.dut.rd_clk)
                await RisingEdge(self.dut.rd_clk)

    async def drive_write(self, item):
        """Drive write transaction"""
        await RisingEdge(self.dut.wr_clk)
        # Mask data to correct width
        data_mask = (1 << self.cfg.DATA_WIDTH) - 1
        self.dut.data_wr.value = item.data & data_mask
        self.dut.wr_en.value = 1

        await RisingEdge(self.dut.wr_clk)
        item.full = bool(self.dut.fifo_full.value)
        item.success = not item.full
        self.dut.wr_en.value = 0

        self.logger.debug(f"WR_DRV: Write: {item.convert2string()}")

    async def drive_read(self, item):
        """Drive read transaction"""
        await RisingEdge(self.dut.rd_clk)
        self.dut.rd_en.value = 1

        await RisingEdge(self.dut.rd_clk)
        item.empty = bool(self.dut.fifo_empty.value)
        item.success = not item.empty

        # Wait extra cycle for buffered read
        if self.cfg.RD_BUFFER:
            await RisingEdge(self.dut.rd_clk)

        item.read_data = int(self.dut.data_rd.value)
        self.dut.rd_en.value = 0

        self.logger.debug(f"RD_DRV: Read: {item.convert2string()}")
