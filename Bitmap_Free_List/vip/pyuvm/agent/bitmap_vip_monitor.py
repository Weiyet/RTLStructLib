from cocotb.triggers import RisingEdge, ReadOnly
from pyuvm import ConfigDB, uvm_monitor, uvm_analysis_port


class BitmapVipMonitor(uvm_monitor):
    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "bitmap_vip_cfg")
        self.ap = uvm_analysis_port("ap", self)

    async def run_phase(self):
        dut = self.cfg.dut
        cycles = 0
        while True:
            await RisingEdge(dut.clk)
            request = tuple(int(getattr(dut, n).value)
                            for n in ("rst", "alloc_req", "free_req", "free_id"))
            await ReadOnly()
            response = tuple(int(getattr(dut, n).value) for n in
                             ("alloc_valid", "alloc_error", "alloc_id", "free_valid",
                              "free_error", "free_count", "exhausted", "all_free"))
            self.ap.write((request, response))
            cycles += 1
            assert cycles <= self.cfg.timeout_cycles, "Bitmap VIP watchdog"
