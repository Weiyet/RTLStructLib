from cocotb.triggers import RisingEdge, ReadOnly
from pyuvm import ConfigDB, uvm_monitor, uvm_analysis_port


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
