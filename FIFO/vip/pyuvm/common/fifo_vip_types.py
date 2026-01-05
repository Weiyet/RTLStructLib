"""
FIFO VIP Types and Enums
Create Date: 01/05/2026
"""

from enum import Enum, auto


class FifoOp(Enum):
    """FIFO operation types"""
    WRITE = auto()
    READ = auto()
    IDLE = auto()


class FifoAgentMode(Enum):
    """Agent mode types"""
    MASTER = auto()
    SLAVE = auto()
    MONITOR_ONLY = auto()
