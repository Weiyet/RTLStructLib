from dataclasses import dataclass
from pyuvm import uvm_sequence_item


@dataclass
class PriorityVipConfig:
    dut: object
    depth: int
    priority_width: int
    data_width: int
    min_first: bool
    active: bool = True
    timeout_cycles: int = 100000
    seed: int = 123

    @classmethod
    def from_dut(cls, dut, **kwargs):
        return cls(dut, int(dut.DEPTH.value), len(dut.req_priority),
                   len(dut.req_data), bool(int(dut.MIN_FIRST.value)), **kwargs)


class PriorityVipItem(uvm_sequence_item):
    def __init__(self, name="item", op=0, priority=0, data=0, stalls=0,
                 reset=False, abort_after=-1):
        super().__init__(name)
        self.op, self.priority, self.data = op, priority, data
        self.stalls = stalls
        self.reset = reset
        self.abort_after = abort_after
        self.aborted = False
        self.response = None
