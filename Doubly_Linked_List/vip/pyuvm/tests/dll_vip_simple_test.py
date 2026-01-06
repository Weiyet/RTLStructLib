"""
Doubly Linked List VIP Simple Test
Create Date: 01/05/2026
"""

from pyuvm import *
import cocotb
from cocotb.triggers import Timer
from .dll_vip_base_test import BaseTest
from ..sequences.dll_vip_insert_seq import DllVipInsertSeq
from ..sequences.dll_vip_read_seq import DllVipReadSeq
from ..sequences.dll_vip_delete_seq import DllVipDeleteSeq


class SimpleTest(BaseTest):
    """Simple test for Doubly Linked List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        """Run phase - execute test"""
        self.raise_objection()

        # Insert some nodes
        insert_seq = DllVipInsertSeq("insert_seq")
        insert_seq.num_inserts = 5
        insert_seq.use_index = False  # Use INSERT_AT_ADDR
        await insert_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        # Read the nodes
        read_seq = DllVipReadSeq("read_seq")
        read_seq.num_reads = 5
        await read_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        # Delete some nodes
        delete_seq = DllVipDeleteSeq("delete_seq")
        delete_seq.num_deletes = 2
        delete_seq.delete_mode = "addr"
        await delete_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        # Read again
        read_seq2 = DllVipReadSeq("read_after_delete")
        read_seq2.num_reads = 3
        await read_seq2.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        self.drop_objection()


class RandomTest(BaseTest):
    """Random test with mixed operations"""

    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        """Run phase - execute test"""
        self.raise_objection()

        # Initial insert burst
        insert_seq = DllVipInsertSeq("init_insert")
        insert_seq.num_inserts = 5
        insert_seq.use_index = False
        await insert_seq.start(self.env.get_sequencer())

        await Timer(100, units="ns")

        # Mixed operations
        for i in range(3):
            # Insert with index
            insert_seq = DllVipInsertSeq(f"insert_{i}")
            insert_seq.num_inserts = 2
            insert_seq.use_index = True
            await insert_seq.start(self.env.get_sequencer())

            await Timer(50, units="ns")

            # Read
            read_seq = DllVipReadSeq(f"read_{i}")
            read_seq.num_reads = 3
            await read_seq.start(self.env.get_sequencer())

            await Timer(50, units="ns")

            # Delete by value
            delete_seq = DllVipDeleteSeq(f"delete_{i}")
            delete_seq.num_deletes = 1
            delete_seq.delete_mode = "value"
            await delete_seq.start(self.env.get_sequencer())

            await Timer(50, units="ns")

        # Final operations
        read_seq = DllVipReadSeq("final_read")
        read_seq.num_reads = 4
        await read_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        # Delete by index
        delete_seq = DllVipDeleteSeq("final_delete")
        delete_seq.num_deletes = 2
        delete_seq.delete_mode = "index"
        await delete_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        self.drop_objection()
