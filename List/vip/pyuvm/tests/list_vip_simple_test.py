"""
List VIP Simple Test
Create Date: 01/05/2026
"""

from pyuvm import *
import cocotb
from cocotb.triggers import Timer
from .list_vip_base_test import BaseTest
from ..sequences.list_vip_insert_seq import ListVipInsertSeq
from ..sequences.list_vip_read_seq import ListVipReadSeq
from ..sequences.list_vip_delete_seq import ListVipDeleteSeq
from ..sequences.list_vip_find_seq import ListVipFindSeq
from ..sequences.list_vip_sort_seq import ListVipSortSeq
from ..sequences.list_vip_sum_seq import ListVipSumSeq


class SimpleTest(BaseTest):
    """Simple test for List VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        """Run phase - execute test"""
        self.raise_objection()

        # Insert some items
        insert_seq = ListVipInsertSeq("insert_seq")
        insert_seq.num_inserts = 5
        insert_seq.random_index = False  # Append at end
        await insert_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        # Read the items
        read_seq = ListVipReadSeq("read_seq")
        read_seq.num_reads = 5
        await read_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        # Sum the items
        sum_seq = ListVipSumSeq("sum_seq")
        await sum_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        # Sort ascending
        sort_seq = ListVipSortSeq("sort_asc_seq")
        sort_seq.ascending = True
        await sort_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        # Read after sort
        read_seq2 = ListVipReadSeq("read_after_sort")
        read_seq2.num_reads = 5
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
        insert_seq = ListVipInsertSeq("init_insert")
        insert_seq.num_inserts = 6
        insert_seq.random_index = False
        await insert_seq.start(self.env.get_sequencer())

        await Timer(100, units="ns")

        # Mixed operations
        for i in range(3):
            # Insert
            insert_seq = ListVipInsertSeq(f"insert_{i}")
            insert_seq.num_inserts = 2
            insert_seq.random_index = True
            await insert_seq.start(self.env.get_sequencer())

            await Timer(50, units="ns")

            # Read
            read_seq = ListVipReadSeq(f"read_{i}")
            read_seq.num_reads = 3
            await read_seq.start(self.env.get_sequencer())

            await Timer(50, units="ns")

            # Find
            find_seq = ListVipFindSeq(f"find_{i}")
            find_seq.num_finds = 2
            find_seq.find_all = False
            await find_seq.start(self.env.get_sequencer())

            await Timer(50, units="ns")

            # Delete
            delete_seq = ListVipDeleteSeq(f"delete_{i}")
            delete_seq.num_deletes = 1
            await delete_seq.start(self.env.get_sequencer())

            await Timer(50, units="ns")

        # Final sum
        sum_seq = ListVipSumSeq("final_sum")
        await sum_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        # Sort and read
        sort_seq = ListVipSortSeq("final_sort")
        sort_seq.ascending = True
        await sort_seq.start(self.env.get_sequencer())

        await Timer(100, units="ns")

        read_seq = ListVipReadSeq("final_read")
        read_seq.num_reads = 5
        await read_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")

        self.drop_objection()
