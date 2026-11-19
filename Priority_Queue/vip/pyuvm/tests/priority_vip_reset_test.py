from .priority_vip_base_test import PriorityVipBaseTest
from ..sequences.priority_vip_reset_seq import PriorityVipResetSequence


class PriorityVipResetTest(PriorityVipBaseTest):
    sequence_type = PriorityVipResetSequence
