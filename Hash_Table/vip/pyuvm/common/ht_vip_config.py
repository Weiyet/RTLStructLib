"""
Hash Table VIP Configuration
Create Date: 01/05/2026

Configuration class for Hash Table VIP
"""

from pyuvm import *


class HtVipConfig(uvm_object):
    """Configuration object for Hash Table VIP"""

    def __init__(self, name="ht_vip_config"):
        super().__init__(name)

        # DUT parameters
        self.KEY_WIDTH = 32
        self.VALUE_WIDTH = 32
        self.TOTAL_INDEX = 8
        self.CHAINING_SIZE = 4
        self.COLLISION_METHOD = "MULTI_STAGE_CHAINING"
        self.HASH_ALGORITHM = "MODULUS"

        # VIP configuration
        self.has_agent = True
        self.enable_scoreboard = True
        self.is_active = True

    def do_print(self, printer=None):
        """Print configuration"""
        self.logger.info(f"KEY_WIDTH: {self.KEY_WIDTH}")
        self.logger.info(f"VALUE_WIDTH: {self.VALUE_WIDTH}")
        self.logger.info(f"TOTAL_INDEX: {self.TOTAL_INDEX}")
        self.logger.info(f"CHAINING_SIZE: {self.CHAINING_SIZE}")
        self.logger.info(f"COLLISION_METHOD: {self.COLLISION_METHOD}")
        self.logger.info(f"HASH_ALGORITHM: {self.HASH_ALGORITHM}")
