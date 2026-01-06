"""Table VIP Sequence Item"""
from pyuvm import uvm_sequence_item
from . import TableOp
import random

class TableVipSeqItem(uvm_sequence_item):
    def __init__(self, name="table_vip_seq_item"):
        super().__init__(name)
        # Operation type
        self.op = TableOp.WRITE

        # Write operation (supports multiple writes)
        self.wr_en = [0, 0]  # 2 write enables
        self.index_wr = [0, 0]  # 2 write indices
        self.data_wr = [0, 0]  # 2 write data

        # Read operation (supports multiple reads)
        self.rd_en = 0
        self.index_rd = [0, 0]  # 2 read indices

        # Read results
        self.data_rd = [0, 0]  # 2 read data

        # Config reference
        self.cfg = None

    def randomize(self):
        """Randomize transaction fields"""
        # Randomize operation
        self.op = random.choice([TableOp.WRITE, TableOp.READ])

        if self.op == TableOp.WRITE:
            # At least one write enable
            self.wr_en = [random.randint(0, 1), random.randint(0, 1)]
            if self.wr_en[0] == 0 and self.wr_en[1] == 0:
                self.wr_en[0] = 1  # Ensure at least one write
            self.rd_en = 0

            # Randomize write indices (valid range)
            table_size = self.cfg.TABLE_SIZE if self.cfg else 32
            self.index_wr = [random.randint(0, table_size-1),
                            random.randint(0, table_size-1)]

            # Randomize write data
            max_val = (1 << (self.cfg.DATA_WIDTH if self.cfg else 8)) - 1
            self.data_wr = [random.randint(0, max_val),
                           random.randint(0, max_val)]

        else:  # READ
            self.rd_en = 1
            self.wr_en = [0, 0]

            # Randomize read indices
            table_size = self.cfg.TABLE_SIZE if self.cfg else 32
            self.index_rd = [random.randint(0, table_size-1),
                            random.randint(0, table_size-1)]

        return True

    def __str__(self):
        if self.op == TableOp.WRITE:
            s = "WRITE: "
            if self.wr_en[0]:
                s += f"idx[0]={self.index_wr[0]} data[0]=0x{self.data_wr[0]:x} "
            if self.wr_en[1]:
                s += f"idx[1]={self.index_wr[1]} data[1]=0x{self.data_wr[1]:x} "
            return s
        else:
            return (f"READ: idx[0]={self.index_rd[0]} data[0]=0x{self.data_rd[0]:x} "
                   f"idx[1]={self.index_rd[1]} data[1]=0x{self.data_rd[1]:x}")
