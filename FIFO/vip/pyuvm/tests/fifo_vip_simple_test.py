"""
FIFO VIP Simple Test
Create Date: 01/05/2026
"""

from pyuvm import *
import cocotb
from cocotb.triggers import Timer
from .fifo_vip_base_test import BaseTest
from ..sequences.fifo_vip_write_req_seq import FifoVipWriteReqSeq
from ..sequences.fifo_vip_read_req_seq import FifoVipReadReqSeq


class SimpleTest(BaseTest):
    """Simple test for FIFO VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        """Run phase - execute test"""
        self.raise_objection()

        # Write some data
        wr_seq = FifoVipWriteReqSeq("wr_seq")
        wr_seq.num_writes = 8
        await wr_seq.start(self.env.get_wr_sequencer())

        # Wait a bit
        await Timer(200, units="ns")

        # Read it back
        rd_seq = FifoVipReadReqSeq("rd_seq")
        rd_seq.num_reads = 8
        await rd_seq.start(self.env.get_rd_sequencer())

        # Wait a bit
        await Timer(200, units="ns")

        self.drop_objection()


class RandomTest(BaseTest):
    """Random test with mixed writes and reads"""

    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        """Run phase - execute test"""
        self.raise_objection()

        # Initial write burst
        wr_seq = FifoVipWriteReqSeq("init_wr_seq")
        wr_seq.num_writes = 10
        await wr_seq.start(self.env.get_wr_sequencer())

        await Timer(100, units="ns")

        # Mixed operations
        for i in range(5):
            # Write burst
            wr_seq = FifoVipWriteReqSeq(f"wr_seq_{i}")
            wr_seq.num_writes = 5
            await wr_seq.start(self.env.get_wr_sequencer())

            await Timer(50, units="ns")

            # Read burst
            rd_seq = FifoVipReadReqSeq(f"rd_seq_{i}")
            rd_seq.num_reads = 3
            await rd_seq.start(self.env.get_rd_sequencer())

            await Timer(50, units="ns")

        # Final read to empty FIFO
        rd_seq = FifoVipReadReqSeq("final_rd_seq")
        rd_seq.num_reads = 20
        await rd_seq.start(self.env.get_rd_sequencer())

        await Timer(200, units="ns")

        self.drop_objection()
