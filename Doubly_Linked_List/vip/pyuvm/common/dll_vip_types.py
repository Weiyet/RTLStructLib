"""
Doubly Linked List VIP Types
Create Date: 01/05/2026

Enumerations and types for Doubly Linked List VIP
"""

from enum import Enum


class DllOp(Enum):
    """Doubly Linked List operation types matching DUT operations"""
    READ_ADDR = 0          # Read data at address
    INSERT_AT_ADDR = 1     # Insert data at address
    DELETE_VALUE = 2       # Delete by value
    DELETE_AT_ADDR = 3     # Delete at address
    IDLE = 4               # No operation
    INSERT_AT_INDEX = 5    # Insert at index
    DELETE_AT_INDEX = 7    # Delete at index
