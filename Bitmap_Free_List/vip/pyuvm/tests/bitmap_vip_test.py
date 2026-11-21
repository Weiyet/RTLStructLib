from cocotb.triggers import FallingEdge
from pyuvm import ConfigDB, uvm_test
from ..env.bitmap_vip_env import BitmapVipEnv
from ..common.bitmap_vip_seq_item import BitmapVipItem
from ..agent.bitmap_vip_driver import drive_cycle
from ..sequences.bitmap_vip_sequence import BitmapVipSequence


class BitmapVipBaseTest(uvm_test):
    scenario = "boundary"

    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "bitmap_vip_cfg")
        self.cfg.active = self.scenario != "passive"
        self.env = BitmapVipEnv("env", self)

    async def run_phase(self):
        self.raise_objection()
        if self.scenario == "passive":
            assert self.env.agent.driver is None and self.env.agent.sequencer is None
            cap = self.cfg.capacity
            await drive_cycle(self.cfg.dut, BitmapVipItem(reset=1, allocate=1, release=1))
            for _ in range(cap + 1):
                await drive_cycle(self.cfg.dut, BitmapVipItem(allocate=1))
            for ident in range(cap):
                await drive_cycle(self.cfg.dut, BitmapVipItem(allocate=1, release=1, ident=ident))
            for ident in range(cap):
                await drive_cycle(self.cfg.dut, BitmapVipItem(release=1, ident=ident))
        elif self.scenario != "empty":
            await BitmapVipSequence("seq", self.cfg, self.scenario).start(self.env.get_sequencer())
        for _ in range(2):
            await FallingEdge(self.cfg.dut.clk)
        assert not self.env.scoreboard.owned, "Scenario did not release all IDs"
        self.drop_objection()


class BitmapVipBoundaryTest(BitmapVipBaseTest):
    scenario = "boundary"


class BitmapVipRandomTest(BitmapVipBaseTest):
    scenario = "random"


class BitmapVipResetTest(BitmapVipBaseTest):
    scenario = "reset"


class BitmapVipPassiveTest(BitmapVipBaseTest):
    scenario = "passive"


class BitmapVipEmptyTest(BitmapVipBaseTest):
    scenario = "empty"
