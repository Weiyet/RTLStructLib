from cocotb.triggers import FallingEdge, RisingEdge, ReadOnly, Timer
from pyuvm import ConfigDB, uvm_driver


async def drive_cycle(dut, item):
    """One cycle; also usable by external stimulus with a passive agent."""
    await FallingEdge(dut.clk)
    dut.rst.value = item.reset
    dut.alloc_req.value = item.allocate
    dut.free_req.value = item.release
    dut.free_id.value = item.ident & ((1 << len(dut.free_id)) - 1)
    await RisingEdge(dut.clk)
    await ReadOnly()
    names = ("alloc_valid", "alloc_error", "alloc_id", "free_valid", "free_error",
             "free_count", "exhausted", "all_free")
    item.response = tuple(int(getattr(dut, name).value) for name in names)
    await Timer(1, units="ns")
    dut.rst.value = 0
    dut.alloc_req.value = 0
    dut.free_req.value = 0


class BitmapVipDriver(uvm_driver):
    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "bitmap_vip_cfg")

    async def run_phase(self):
        while True:
            item = await self.seq_item_port.get_next_item()
            await drive_cycle(self.cfg.dut, item)
            self.seq_item_port.item_done()
