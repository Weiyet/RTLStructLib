"""Hash Table VIP Simple Test"""
from pyuvm import *
from cocotb.triggers import Timer
from .ht_vip_base_test import BaseTest
from ..sequences.ht_vip_insert_seq import HtVipInsertSeq
from ..sequences.ht_vip_search_seq import HtVipSearchSeq
from ..sequences.ht_vip_delete_seq import HtVipDeleteSeq

class SimpleTest(BaseTest):
    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        self.raise_objection()

        # Insert some key-value pairs
        insert_seq = HtVipInsertSeq("insert_seq")
        insert_seq.num_inserts = 5
        await insert_seq.start(self.env.get_sequencer())
        await Timer(200, units="ns")

        # Search for keys
        search_seq = HtVipSearchSeq("search_seq")
        search_seq.num_searches = 5
        await search_seq.start(self.env.get_sequencer())
        await Timer(200, units="ns")

        # Delete some keys
        delete_seq = HtVipDeleteSeq("delete_seq")
        delete_seq.num_deletes = 2
        await delete_seq.start(self.env.get_sequencer())
        await Timer(200, units="ns")

        self.drop_objection()

class RandomTest(BaseTest):
    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        self.raise_objection()

        # Initial inserts
        insert_seq = HtVipInsertSeq("init_insert")
        insert_seq.num_inserts = 6
        await insert_seq.start(self.env.get_sequencer())
        await Timer(100, units="ns")

        # Mixed operations
        for i in range(3):
            insert_seq = HtVipInsertSeq(f"insert_{i}")
            insert_seq.num_inserts = 2
            await insert_seq.start(self.env.get_sequencer())
            await Timer(50, units="ns")

            search_seq = HtVipSearchSeq(f"search_{i}")
            search_seq.num_searches = 3
            await search_seq.start(self.env.get_sequencer())
            await Timer(50, units="ns")

            delete_seq = HtVipDeleteSeq(f"delete_{i}")
            delete_seq.num_deletes = 1
            await delete_seq.start(self.env.get_sequencer())
            await Timer(50, units="ns")

        await Timer(200, units="ns")
        self.drop_objection()
