"""
Singly Linked List VIP Configuration
Create Date: 01/05/2026

Configuration class for Singly Linked List VIP
"""

from pyuvm import *


class SllVipConfig(uvm_object):
    """Configuration object for Singly Linked List VIP"""

    def __init__(self, name="sll_vip_config"):
        super().__init__(name)

        # DUT parameters
        self.DATA_WIDTH = 8
        self.MAX_NODE = 8

        # VIP configuration
        self.has_agent = True
        self.enable_scoreboard = True
        self.is_active = True

    def do_print(self, printer=None):
        """Print configuration"""
        self.logger.info(f"DATA_WIDTH: {self.DATA_WIDTH}")
        self.logger.info(f"MAX_NODE: {self.MAX_NODE}")
        self.logger.info(f"has_agent: {self.has_agent}")
        self.logger.info(f"enable_scoreboard: {self.enable_scoreboard}")
