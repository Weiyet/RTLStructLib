"""
List VIP Types
Create Date: 01/05/2026

Enumerations and types for List VIP
"""

from enum import Enum, auto


class ListOp(Enum):
    """List operation types matching DUT operations"""
    READ = 0       # Read data at index
    INSERT = 1     # Insert data at index
    FIND_ALL = 2   # Find all indices of value
    FIND_1ST = 3   # Find first index of value
    SUM = 4        # Sum all elements
    SORT_ASC = 5   # Sort ascending
    SORT_DES = 6   # Sort descending
    DELETE = 7     # Delete element at index
    IDLE = 8       # No operation


class ListAgentMode(Enum):
    """Agent operation modes"""
    MASTER = auto()
    SLAVE = auto()
    MONITOR_ONLY = auto()
