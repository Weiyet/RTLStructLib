"""Table VIP Scoreboard"""
from pyuvm import uvm_scoreboard, uvm_analysis_imp
from ..common import TableOp

class TableVipScoreboard(uvm_scoreboard):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.analysis_export = uvm_analysis_imp("analysis_export", self)
        self.cfg = None
        self.table_model = {}  # Python dict as table reference model
        self.write_count = 0
        self.read_count = 0

    def build_phase(self):
        super().build_phase()
        from pyuvm import ConfigDB
        arr = []
        if not ConfigDB().get(self, "", "table_vip_cfg", arr):
            self.logger.critical("No config found in ConfigDB!")
        else:
            self.cfg = arr[0]

        # Initialize table model
        for i in range(32):
            self.table_model[i] = 0x00

    def write(self, item):
        """Receive transaction from monitor"""
        self.logger.info(f"Checking: {item}")

        if item.op == TableOp.WRITE:
            self.check_write(item)
        elif item.op == TableOp.READ:
            self.check_read(item)

    def check_write(self, item):
        """Check WRITE operation"""
        self.write_count += 1

        # Update model based on write enables
        if item.wr_en[0]:
            self.table_model[item.index_wr[0]] = item.data_wr[0]
            self.logger.debug(f"Updated table[{item.index_wr[0]}] = 0x{item.data_wr[0]:x}")

        if item.wr_en[1]:
            self.table_model[item.index_wr[1]] = item.data_wr[1]
            self.logger.debug(f"Updated table[{item.index_wr[1]}] = 0x{item.data_wr[1]:x}")

    def check_read(self, item):
        """Check READ operation"""
        self.read_count += 1

        # Check read data[0]
        if item.data_rd[0] != self.table_model[item.index_rd[0]]:
            self.logger.error(f"Read[0] mismatch at index {item.index_rd[0]}: "
                            f"expected=0x{self.table_model[item.index_rd[0]]:x} "
                            f"actual=0x{item.data_rd[0]:x}")
        else:
            self.logger.debug(f"Read[0] matched: table[{item.index_rd[0]}] = 0x{item.data_rd[0]:x}")

        # Check read data[1]
        if item.data_rd[1] != self.table_model[item.index_rd[1]]:
            self.logger.error(f"Read[1] mismatch at index {item.index_rd[1]}: "
                            f"expected=0x{self.table_model[item.index_rd[1]]:x} "
                            f"actual=0x{item.data_rd[1]:x}")
        else:
            self.logger.debug(f"Read[1] matched: table[{item.index_rd[1]}] = 0x{item.data_rd[1]:x}")

    def report_phase(self):
        self.logger.info("=" * 50)
        self.logger.info("=== Table Statistics ===")
        self.logger.info(f"Total Writes: {self.write_count}")
        self.logger.info(f"Total Reads: {self.read_count}")
        self.logger.info("=" * 50)
