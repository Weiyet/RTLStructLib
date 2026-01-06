"""
List VIP Driver
Create Date: 01/05/2026

Driver for List VIP - drives transactions to DUT
"""

from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge, Timer
from ..common.list_vip_seq_item import ListVipSeqItem
from ..common.list_vip_types import ListOp
from ..common.list_vip_config import ListVipConfig


class ListVipDriver(uvm_driver):
    """Driver for List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        self.cfg = ConfigDB().get(self, "", "list_vip_cfg")
        if self.cfg is None:
            self.logger.error("No config object found")

    async def run_phase(self):
        await self.get_dut()

        # Initialize signals
        self.dut.op_sel.value = 0
        self.dut.op_en.value = 0
        self.dut.data_in.value = 0
        self.dut.index_in.value = 0

        while True:
            item = await self.seq_item_port.get_next_item()
            await self.drive_item(item)
            self.seq_item_port.item_done()

    async def get_dut(self):
        """Get DUT handle from ConfigDB"""
        self.dut = ConfigDB().get(self, "", "list_vip_dut")
        if self.dut is None:
            self.logger.error("No DUT found in ConfigDB")

    async def drive_item(self, item):
        """Drive transaction based on operation type"""
        if item.op == ListOp.READ:
            await self.drive_read(item)
        elif item.op == ListOp.INSERT:
            await self.drive_insert(item)
        elif item.op == ListOp.DELETE:
            await self.drive_delete(item)
        elif item.op == ListOp.FIND_1ST:
            await self.drive_find_1st(item)
        elif item.op == ListOp.FIND_ALL:
            await self.drive_find_all(item)
        elif item.op == ListOp.SUM:
            await self.drive_sum(item)
        elif item.op == ListOp.SORT_ASC:
            await self.drive_sort_asc(item)
        elif item.op == ListOp.SORT_DES:
            await self.drive_sort_des(item)
        elif item.op == ListOp.IDLE:
            await self.drive_idle()

    async def drive_read(self, item):
        """Drive READ operation"""
        await RisingEdge(self.dut.clk)
        self.dut.op_sel.value = 0b000
        self.dut.op_en.value = 1
        self.dut.index_in.value = item.index

        await RisingEdge(self.dut.clk)
        # Wait for op_done
        while not self.dut.op_done.value:
            await RisingEdge(self.dut.clk)

        item.result_data = int(self.dut.data_out.value)
        item.op_done = bool(self.dut.op_done.value)
        item.op_error = bool(self.dut.op_error.value)
        item.current_len = int(self.dut.len.value)

        await RisingEdge(self.dut.clk)
        self.dut.op_en.value = 0

        self.logger.debug(f"READ[{item.index}]: data=0x{item.result_data:x} error={item.op_error}")

    async def drive_insert(self, item):
        """Drive INSERT operation"""
        await RisingEdge(self.dut.clk)
        self.dut.op_sel.value = 0b001
        self.dut.op_en.value = 1
        self.dut.index_in.value = item.index
        data_mask = (1 << self.cfg.DATA_WIDTH) - 1
        self.dut.data_in.value = item.data & data_mask

        await RisingEdge(self.dut.clk)
        # Wait for op_done
        while not self.dut.op_done.value:
            await RisingEdge(self.dut.clk)

        item.op_done = bool(self.dut.op_done.value)
        item.op_error = bool(self.dut.op_error.value)
        item.current_len = int(self.dut.len.value)

        await RisingEdge(self.dut.clk)
        self.dut.op_en.value = 0

        self.logger.debug(f"INSERT[{item.index}]: data=0x{item.data:x} error={item.op_error} len={item.current_len}")

    async def drive_delete(self, item):
        """Drive DELETE operation"""
        await RisingEdge(self.dut.clk)
        self.dut.op_sel.value = 0b111
        self.dut.op_en.value = 1
        self.dut.index_in.value = item.index

        await RisingEdge(self.dut.clk)
        # Wait for op_done
        while not self.dut.op_done.value:
            await RisingEdge(self.dut.clk)

        item.op_done = bool(self.dut.op_done.value)
        item.op_error = bool(self.dut.op_error.value)
        item.current_len = int(self.dut.len.value)

        await RisingEdge(self.dut.clk)
        self.dut.op_en.value = 0

        self.logger.debug(f"DELETE[{item.index}]: error={item.op_error} len={item.current_len}")

    async def drive_find_1st(self, item):
        """Drive FIND_1ST operation"""
        await RisingEdge(self.dut.clk)
        self.dut.op_sel.value = 0b011
        self.dut.op_en.value = 1
        data_mask = (1 << self.cfg.DATA_WIDTH) - 1
        self.dut.data_in.value = item.data & data_mask

        await RisingEdge(self.dut.clk)
        # Wait for op_done
        while not self.dut.op_done.value:
            await RisingEdge(self.dut.clk)

        item.result_data = int(self.dut.data_out.value)
        item.op_done = bool(self.dut.op_done.value)
        item.op_error = bool(self.dut.op_error.value)

        await RisingEdge(self.dut.clk)
        self.dut.op_en.value = 0

        self.logger.debug(f"FIND_1ST(0x{item.data:x}): index={item.result_data} error={item.op_error}")

    async def drive_find_all(self, item):
        """Drive FIND_ALL operation"""
        await RisingEdge(self.dut.clk)
        self.dut.op_sel.value = 0b010
        self.dut.op_en.value = 1
        data_mask = (1 << self.cfg.DATA_WIDTH) - 1
        self.dut.data_in.value = item.data & data_mask

        await RisingEdge(self.dut.clk)
        # Wait for operation to complete (can take multiple cycles)
        while not self.dut.op_done.value or self.dut.op_in_progress.value:
            await RisingEdge(self.dut.clk)

        item.result_data = int(self.dut.data_out.value)
        item.op_done = bool(self.dut.op_done.value)
        item.op_error = bool(self.dut.op_error.value)

        self.dut.op_en.value = 0

        self.logger.debug(f"FIND_ALL(0x{item.data:x}): completed error={item.op_error}")

    async def drive_sum(self, item):
        """Drive SUM operation"""
        await RisingEdge(self.dut.clk)
        self.dut.op_sel.value = 0b100
        self.dut.op_en.value = 1

        await RisingEdge(self.dut.clk)
        # Wait for op_done
        while not self.dut.op_done.value:
            await RisingEdge(self.dut.clk)

        item.result_data = int(self.dut.data_out.value)
        item.op_done = bool(self.dut.op_done.value)
        item.op_error = bool(self.dut.op_error.value)

        await RisingEdge(self.dut.clk)
        self.dut.op_en.value = 0

        self.logger.debug(f"SUM: result={item.result_data} error={item.op_error}")

    async def drive_sort_asc(self, item):
        """Drive SORT_ASC operation"""
        await RisingEdge(self.dut.clk)
        self.dut.op_sel.value = 0b101
        self.dut.op_en.value = 1

        await RisingEdge(self.dut.clk)
        # Wait for op_done
        while not self.dut.op_done.value:
            await RisingEdge(self.dut.clk)

        item.op_done = bool(self.dut.op_done.value)
        item.op_error = bool(self.dut.op_error.value)

        await RisingEdge(self.dut.clk)
        self.dut.op_en.value = 0

        self.logger.debug("SORT_ASC: completed")

    async def drive_sort_des(self, item):
        """Drive SORT_DES operation"""
        await RisingEdge(self.dut.clk)
        self.dut.op_sel.value = 0b110
        self.dut.op_en.value = 1

        await RisingEdge(self.dut.clk)
        # Wait for op_done
        while not self.dut.op_done.value:
            await RisingEdge(self.dut.clk)

        item.op_done = bool(self.dut.op_done.value)
        item.op_error = bool(self.dut.op_error.value)

        await RisingEdge(self.dut.clk)
        self.dut.op_en.value = 0

        self.logger.debug("SORT_DES: completed")

    async def drive_idle(self):
        """Drive IDLE (no operation)"""
        await RisingEdge(self.dut.clk)
        self.dut.op_en.value = 0
