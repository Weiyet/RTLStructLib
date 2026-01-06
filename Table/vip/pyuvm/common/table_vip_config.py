"""Table VIP Configuration"""
from pyuvm import uvm_object

class TableVipConfig(uvm_object):
    def __init__(self, name="table_vip_config"):
        super().__init__(name)
        # DUT parameters
        self.TABLE_SIZE = 32
        self.DATA_WIDTH = 8
        self.INPUT_RATE = 2
        self.OUTPUT_RATE = 2
