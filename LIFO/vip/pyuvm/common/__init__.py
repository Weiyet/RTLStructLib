"""LIFO VIP Common Components"""
from enum import IntEnum

class LifoOp(IntEnum):
    """LIFO Operation Types"""
    PUSH = 0
    POP = 1
    IDLE = 2
