"""LIFO VIP Simple Test"""
from pyuvm import *
from cocotb.triggers import Timer
from .lifo_vip_base_test import BaseTest
from ..sequences.lifo_vip_push_seq import LifoVipPushSeq
from ..sequences.lifo_vip_pop_seq import LifoVipPopSeq
from ..sequences.lifo_vip_random_seq import LifoVipRandomSeq

class SimpleTest(BaseTest):
    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        self.raise_objection()

        # Push some data
        push_seq = LifoVipPushSeq("push_seq")
        push_seq.cfg = self.cfg
        push_seq.num_trans = 10
        await push_seq.start(self.env.get_sequencer())

        # Pop some data
        pop_seq = LifoVipPopSeq("pop_seq")
        pop_seq.cfg = self.cfg
        pop_seq.num_trans = 5
        await pop_seq.start(self.env.get_sequencer())

        # Random sequence
        rand_seq = LifoVipRandomSeq("rand_seq")
        rand_seq.cfg = self.cfg
        rand_seq.num_trans = 20
        await rand_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")
        self.drop_objection()
