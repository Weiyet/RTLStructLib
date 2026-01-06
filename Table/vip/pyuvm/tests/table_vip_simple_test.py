"""Table VIP Simple Test"""
from pyuvm import *
from cocotb.triggers import Timer
from .table_vip_base_test import BaseTest
from ..sequences.table_vip_write_seq import TableVipWriteSeq
from ..sequences.table_vip_read_seq import TableVipReadSeq
from ..sequences.table_vip_random_seq import TableVipRandomSeq

class SimpleTest(BaseTest):
    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        self.raise_objection()

        # Write some data
        write_seq = TableVipWriteSeq("write_seq")
        write_seq.cfg = self.cfg
        write_seq.num_trans = 10
        await write_seq.start(self.env.get_sequencer())

        # Read some data
        read_seq = TableVipReadSeq("read_seq")
        read_seq.cfg = self.cfg
        read_seq.num_trans = 5
        await read_seq.start(self.env.get_sequencer())

        # Random sequence
        rand_seq = TableVipRandomSeq("rand_seq")
        rand_seq.cfg = self.cfg
        rand_seq.num_trans = 20
        await rand_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")
        self.drop_objection()
