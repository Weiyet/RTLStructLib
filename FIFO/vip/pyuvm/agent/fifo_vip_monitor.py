"""
FIFO VIP Monitor
Create Date: 01/05/2026
"""

from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge, FallingEdge
from ..common.fifo_vip_seq_item import FifoVipSeqItem
from ..common.fifo_vip_types import FifoOp


class FifoVipMonitor(uvm_monitor):
    """Monitor for FIFO transactions"""

    def __init__(self, name, parent, monitor_type="WR"):
        super().__init__(name, parent)
        self.monitor_type = monitor_type  # "WR" or "RD"
        self.dut = None
        self.cfg = None
        self.ap = uvm_analysis_port("ap", self)

    def build_phase(self):
        super().build_phase()
        # Get DUT handle
        self.dut = cocotb.top
        # Get config
        self.cfg = ConfigDB().get(self, "", "fifo_vip_cfg")
        if self.cfg is None:
            self.logger.critical("No config found")

    async def run_phase(self):
        """Main monitor run phase"""
        # Wait for reset
        await FallingEdge(self.dut.rst)

        if self.monitor_type == "WR":
            await self.monitor_writes()
        else:
            await self.monitor_reads()

    async def monitor_writes(self):
        """Monitor write transactions"""
        while True:
            await RisingEdge(self.dut.wr_clk)
            if self.dut.wr_en.value == 1 and self.dut.rst.value == 0:
                item = FifoVipSeqItem("wr_item")
                item.op = FifoOp.WRITE
                item.data = int(self.dut.data_wr.value)
                item.full = bool(self.dut.fifo_full.value)
                item.success = not item.full
                self.ap.write(item)
                self.logger.debug(f"WR_MON: Monitored: {item.convert2string()}")

    async def monitor_reads(self):
        """Monitor read transactions"""
        while True:
            await RisingEdge(self.dut.rd_clk)
            if self.dut.rd_en.value == 1 and self.dut.rst.value == 0:
                item = FifoVipSeqItem("rd_item")
                item.op = FifoOp.READ
                item.empty = bool(self.dut.fifo_empty.value)
                item.success = not item.empty

                # Wait for buffered read
                if self.cfg.RD_BUFFER:
                    await RisingEdge(self.dut.rd_clk)

                item.read_data = int(self.dut.data_rd.value)
                self.ap.write(item)
                self.logger.debug(f"RD_MON: Monitored: {item.convert2string()}")
