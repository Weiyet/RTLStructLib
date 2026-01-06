"""Dual Edge FF VIP Sequencer"""
from pyuvm import *

class DeffVipSequencer(uvm_sequencer):
    def __init__(self, name, parent):
        super().__init__(name, parent)
