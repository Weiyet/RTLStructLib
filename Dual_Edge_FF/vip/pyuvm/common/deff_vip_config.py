"""Dual Edge FF VIP Configuration"""
from pyuvm import *

class DeffVipConfig(uvm_object):
    def __init__(self, name="deff_vip_config"):
        super().__init__(name)
        self.DATA_WIDTH = 8
        self.RESET_VALUE = 0x00
        self.has_agent = True
        self.enable_scoreboard = True
        self.is_active = True
