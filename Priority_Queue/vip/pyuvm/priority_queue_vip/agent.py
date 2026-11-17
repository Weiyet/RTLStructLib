from cocotb.triggers import FallingEdge, RisingEdge, ReadOnly
from pyuvm import ConfigDB, uvm_agent, uvm_driver, uvm_monitor, uvm_sequencer, uvm_analysis_port


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


class PriorityVipMonitor(uvm_monitor):
    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "priority_vip_cfg")
        self.ap = uvm_analysis_port("ap", self)

    def sample(self):
        d = self.cfg.dut
        fields = ("rst", "req_valid", "req_ready", "rsp_valid", "rsp_ready", "count", "full", "empty")
        result = {key: int(getattr(d, key).value) for key in fields}
        result.update(req_op=0, req_priority=0, req_data=0, rsp_error=0, rsp_priority=0, rsp_data=0)
        if not result["rst"] and result["req_valid"] and result["req_ready"]:
            result["req_op"] = int(d.req_op.value)
            if result["req_op"] == 0 and not result["full"]:
                result["req_priority"] = int(d.req_priority.value)
                result["req_data"] = int(d.req_data.value)
        if result["rst"] or result["rsp_valid"]:
            for key in ("rsp_error", "rsp_priority", "rsp_data"):
                result[key] = int(getattr(d, key).value)
        return result

    async def run_phase(self):
        d = self.cfg.dut
        cycles = 0
        while True:
            await RisingEdge(d.clk)
            # Read before RTL NBA updates: these are the actual transfer values.
            pre = {"rst": 1} if int(d.rst.value) else self.sample()
            await ReadOnly()
            post = self.sample()
            self.ap.write((pre, post))
            cycles += 1
            assert cycles <= self.cfg.timeout_cycles, "Priority VIP timed out"


class PriorityVipAgent(uvm_agent):
    def build_phase(self):
        cfg = ConfigDB().get(self, "", "priority_vip_cfg")
        self.monitor = PriorityVipMonitor("monitor", self)
        self.sequencer = self.driver = None
        if cfg.active:
            self.sequencer = uvm_sequencer("sequencer", self)
            self.driver = PriorityVipDriver("driver", self)

    def connect_phase(self):
        if self.driver is not None:
            self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
