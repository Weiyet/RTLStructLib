from dataclasses import dataclass


@dataclass
class BitmapVipConfig:
    dut: object
    capacity: int
    id_width: int
    active: bool = True
    seed: int = 123
    timeout_cycles: int = 20000

    @classmethod
    def from_dut(cls, dut, **kwargs):
        capacity = int(dut.CAPACITY.value)
        width = max(1, (capacity - 1).bit_length())
        assert capacity > 0 and len(dut.free_id) == width
        return cls(dut, capacity, width, **kwargs)
