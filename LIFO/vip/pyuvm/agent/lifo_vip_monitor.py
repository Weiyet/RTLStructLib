"""LIFO VIP Monitor"""
from pyuvm import uvm_monitor
from cocotb.triggers import RisingEdge
from ..common.lifo_vip_seq_item import LifoVipSeqItem
from ..common import LifoOp

class LifoVipMonitor(uvm_monitor):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None
        from pyuvm import uvm_analysis_port
        self.ap = uvm_analysis_port("ap", self)

    def build_phase(self):
        super().build_phase()
        from pyuvm import ConfigDB
        arr = []
        if not ConfigDB().get(self, "", "lifo_vip_dut", arr):
            self.logger.critical("No DUT found in ConfigDB!")
        else:
            self.dut = arr[0]

        arr = []
        if not ConfigDB().get(self, "", "lifo_vip_cfg", arr):
            self.logger.critical("No config found in ConfigDB!")
        else:
            self.cfg = arr[0]

    async def run_phase(self):
        while True:
            await RisingEdge(self.dut.clk)

            wr_en = bool(self.dut.wr_en.value)
            rd_en = bool(self.dut.rd_en.value)

            # Detect push operation
            if wr_en and not rd_en:
                item = LifoVipSeqItem("item")
                item.op = LifoOp.PUSH
                item.data = int(self.dut.data_wr.value)
                item.full = bool(self.dut.lifo_full.value)
                item.success = not item.full
                self.ap.write(item)
                self.logger.debug(f"Observed PUSH: data=0x{item.data:x} full={item.full}")

            # Detect pop operation
            elif rd_en and not wr_en:
                await RisingEdge(self.dut.clk)  # Wait one cycle to capture read data
                item = LifoVipSeqItem("item")
                item.op = LifoOp.POP
                item.read_data = int(self.dut.data_rd.value)
                item.empty = bool(self.dut.lifo_empty.value)
                item.success = not item.empty
                self.ap.write(item)
                self.logger.debug(f"Observed POP: data=0x{item.read_data:x} empty={item.empty}")

            # Detect simultaneous push/pop (bypass)
            elif wr_en and rd_en:
                await RisingEdge(self.dut.clk)
                item = LifoVipSeqItem("item")
                item.op = LifoOp.PUSH  # Record as push for scoreboard
                item.data = int(self.dut.data_wr.value)
                item.read_data = int(self.dut.data_rd.value)  # Bypass data
                item.full = bool(self.dut.lifo_full.value)
                item.empty = bool(self.dut.lifo_empty.value)
                self.ap.write(item)
                self.logger.debug(f"Observed BYPASS: wr=0x{item.data:x} rd=0x{item.read_data:x}")
