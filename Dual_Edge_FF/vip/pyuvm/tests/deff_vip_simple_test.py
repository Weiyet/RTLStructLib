"""Dual Edge FF VIP Simple Test"""
from pyuvm import *
from cocotb.triggers import Timer
from .deff_vip_base_test import BaseTest
from ..sequences.deff_vip_random_seq import DeffVipRandomSeq

class SimpleTest(BaseTest):
    def __init__(self, name, parent):
        super().__init__(name, parent)

    async def run_phase(self):
        self.raise_objection()

        # Run random sequence
        rand_seq = DeffVipRandomSeq("rand_seq")
        rand_seq.num_trans = 20
        await rand_seq.start(self.env.get_sequencer())

        await Timer(200, units="ns")
        self.drop_objection()
