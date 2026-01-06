"""LIFO VIP Configuration"""
from pyuvm import uvm_object

class LifoVipConfig(uvm_object):
    def __init__(self, name="lifo_vip_config"):
        super().__init__(name)
        # DUT parameters
        self.DEPTH = 12
        self.DATA_WIDTH = 8

        # VIP configuration
        self.has_agent = True
        self.enable_scoreboard = True
        self.is_active = True
