from cocotb.triggers import FallingEdge, RisingEdge
from pyuvm import ConfigDB, uvm_driver


class PriorityVipDriver(uvm_driver):
    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "priority_vip_cfg")
        self.dut = self.cfg.dut

    async def reset_bus(self):
        d = self.dut
        d.req_valid.value = 0
        d.rsp_ready.value = 0
        d.rst.value = 1
        for _ in range(3):
            await FallingEdge(d.clk)
        d.rst.value = 0
        await FallingEdge(d.clk)

    async def drive(self, item):
        d = self.dut
        await FallingEdge(d.clk)
        if item.reset:
            await self.reset_bus()
            return
        for _ in range(self.cfg.timeout_cycles):
            if int(d.req_ready.value) and not int(d.rst.value):
                break
            await FallingEdge(d.clk)
        else:
            raise AssertionError("VIP request timed out")
        d.req_op.value = item.op
        d.req_priority.value = item.priority & ((1 << self.cfg.priority_width) - 1)
        d.req_data.value = item.data & ((1 << self.cfg.data_width) - 1)
        d.req_valid.value = 1
        d.rsp_ready.value = 0
        await RisingEdge(d.clk)
        assert int(d.req_ready.value), "Request was not accepted"
        await FallingEdge(d.clk)
        d.req_valid.value = 0
        if item.abort_after >= 0:
            for _ in range(item.abort_after):
                await FallingEdge(d.clk)
            await self.reset_bus()
            item.aborted = True
            return
        for _ in range(self.cfg.timeout_cycles):
            if int(d.rst.value):
                item.aborted = True
                return
            if int(d.rsp_valid.value):
                break
            await FallingEdge(d.clk)
        else:
            raise AssertionError("VIP response timed out")
        for _ in range(item.stalls):
            await FallingEdge(d.clk)
        if int(d.rst.value):
            item.aborted = True
            return
        item.response = (int(d.rsp_error.value), int(d.rsp_priority.value), int(d.rsp_data.value))
        d.rsp_ready.value = 1
        await RisingEdge(d.clk)
        if int(d.rst.value):
            item.response = None
            item.aborted = True
        else:
            assert int(d.rsp_valid.value), "Response was not accepted"
        await FallingEdge(d.clk)
        d.rsp_ready.value = 0

    async def run_phase(self):
        while True:
            item = await self.seq_item_port.get_next_item()
            await self.drive(item)
            self.seq_item_port.item_done()
