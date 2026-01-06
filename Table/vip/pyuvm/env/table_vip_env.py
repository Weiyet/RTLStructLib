"""Table VIP Environment"""
from pyuvm import uvm_env, ConfigDB
from ..agent.table_vip_agent import TableVipAgent
from .table_vip_scoreboard import TableVipScoreboard

class TableVipEnv(uvm_env):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.agent = None
        self.scoreboard = None
        self.cfg = None

    def build_phase(self):
        super().build_phase()
        arr = []
        if not ConfigDB().get(self, "", "table_vip_cfg", arr):
            self.logger.critical("No config found in ConfigDB!")
        else:
            self.cfg = arr[0]

        # Create agent and scoreboard
        self.agent = TableVipAgent("agent", self)
        self.scoreboard = TableVipScoreboard("scoreboard", self)

    def connect_phase(self):
        super().connect_phase()
        self.agent.monitor.ap.connect(self.scoreboard.analysis_export)

    def get_sequencer(self):
        """Return sequencer for use by sequences"""
        if self.agent and self.agent.sequencer:
            return self.agent.sequencer
        return None
