"""
Hash Table VIP Types
Create Date: 01/05/2026

Enumerations and types for Hash Table VIP
"""

from enum import Enum


class HtOp(Enum):
    """Hash Table operation types matching DUT operations"""
    INSERT = 0  # Insert key-value pair
    DELETE = 1  # Delete by key
    SEARCH = 2  # Search by key
    IDLE = 3    # No operation
