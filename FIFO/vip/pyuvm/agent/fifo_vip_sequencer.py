"""
FIFO VIP Sequencer
Create Date: 01/05/2026
"""

from pyuvm import *


class FifoVipSequencer(uvm_sequencer):
    """Sequencer for FIFO transactions"""

    def __init__(self, name, parent):
        super().__init__(name, parent)

    def build_phase(self):
        super().build_phase()
