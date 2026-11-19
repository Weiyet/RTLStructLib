from pyuvm import uvm_sequence_item


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
