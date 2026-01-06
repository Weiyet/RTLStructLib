"""
List VIP Configuration
Create Date: 01/05/2026

Configuration class for List VIP
"""

from pyuvm import *


class ListVipConfig(uvm_object):
    """Configuration object for List VIP"""

    def __init__(self, name="list_vip_config"):
        super().__init__(name)

        # DUT parameters
        self.DATA_WIDTH = 8
        self.LENGTH = 8         # Maximum list length
        self.SUM_METHOD = 0     # 0: parallel, 1: sequential, 2: adder tree

        # VIP configuration
        self.has_agent = True
        self.enable_scoreboard = True
        self.is_active = True

    def do_print(self, printer=None):
        """Print configuration"""
        self.logger.info(f"DATA_WIDTH: {self.DATA_WIDTH}")
        self.logger.info(f"LENGTH: {self.LENGTH}")
        self.logger.info(f"SUM_METHOD: {self.SUM_METHOD}")
        self.logger.info(f"has_agent: {self.has_agent}")
        self.logger.info(f"enable_scoreboard: {self.enable_scoreboard}")
