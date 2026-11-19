from .priority_vip_base_test import PriorityVipBaseTest
from ..sequences.priority_vip_random_seq import PriorityVipRandomSequence


class PriorityVipRandomTest(PriorityVipBaseTest):
    sequence_type = PriorityVipRandomSequence
