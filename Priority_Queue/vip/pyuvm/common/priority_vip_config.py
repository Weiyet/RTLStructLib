from dataclasses import dataclass


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
