from pyuvm import uvm_sequence_item


class BitmapVipItem(uvm_sequence_item):
    def __init__(self, name="item", allocate=0, release=0, ident=0, reset=0):
        super().__init__(name)
        self.allocate = allocate
        self.release = release
        self.ident = ident
        self.reset = reset
        self.response = None
