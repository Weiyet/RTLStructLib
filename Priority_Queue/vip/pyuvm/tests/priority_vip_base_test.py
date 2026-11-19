from cocotb.triggers import FallingEdge
from pyuvm import ConfigDB, uvm_test
from ..env.priority_vip_env import PriorityVipEnv
from ..sequences.priority_vip_boundary_seq import PriorityVipBoundarySequence


class PriorityVipBaseTest(uvm_test):
    sequence_type = PriorityVipBoundarySequence

    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "priority_vip_cfg")
        self.env = PriorityVipEnv("env", self)

    async def run_phase(self):
        self.raise_objection()
        await self.sequence_type("sequence", self.cfg).start(self.env.get_sequencer())
        for _ in range(3):
            await FallingEdge(self.cfg.dut.clk)
        assert self.env.scoreboard.occupancy == 0
        self.drop_objection()
