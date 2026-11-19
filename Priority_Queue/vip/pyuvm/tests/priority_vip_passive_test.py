from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.binary import BinaryValue
from pyuvm import ConfigDB
from .priority_vip_base_test import PriorityVipBaseTest


class PriorityVipPassiveTest(PriorityVipBaseTest):
    def build_phase(self):
        ConfigDB().get(self, "", "priority_vip_cfg").active = False
        super().build_phase()

    async def run_phase(self):
        self.raise_objection()
        assert self.env.agent.driver is None and self.env.agent.sequencer is None
        d = self.cfg.dut
        for _ in range(3):
            await FallingEdge(d.clk)
        d.rst.value = 0
        for op in (0, 2, 1, 1, 3):
            await FallingEdge(d.clk)
            assert int(d.req_ready.value)
            d.req_valid.value = 1
            d.req_op.value = op
            d.req_priority.value = 3 & ((1 << self.cfg.priority_width)-1) if op == 0 else BinaryValue("x" * self.cfg.priority_width)
            d.req_data.value = 37 & ((1 << self.cfg.data_width)-1) if op == 0 else BinaryValue("x" * self.cfg.data_width)
            await RisingEdge(d.clk)
            await FallingEdge(d.clk)
            d.req_valid.value = 0
            d.req_op.value = BinaryValue("xx")
            d.req_priority.value = BinaryValue("x" * self.cfg.priority_width)
            d.req_data.value = BinaryValue("x" * self.cfg.data_width)
            while not int(d.rsp_valid.value):
                await FallingEdge(d.clk)
            for _ in range(2):
                await FallingEdge(d.clk)
            d.rsp_ready.value = 1
            await RisingEdge(d.clk)
            await FallingEdge(d.clk)
            d.rsp_ready.value = 0
        for _ in range(3):
            await FallingEdge(d.clk)
        assert self.env.scoreboard.completed == 5
        assert self.env.scoreboard.occupancy == 0
        self.drop_objection()
