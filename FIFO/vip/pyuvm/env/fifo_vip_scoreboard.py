"""
FIFO VIP Scoreboard
Create Date: 01/05/2026
"""

from pyuvm import *
from ..common.fifo_vip_types import FifoOp


class FifoVipScoreboard(uvm_scoreboard):
    """Scoreboard for FIFO VIP"""

    def __init__(self, name, parent):
        super().__init__(name, parent)
        # Simple queue model
        self.fifo_model = []
        self.errors = 0
        self.wr_count = 0
        self.rd_count = 0

        # Create analysis exports
        self.wr_export = uvm_analysis_export("wr_export", self)
        self.rd_export = uvm_analysis_export("rd_export", self)

    def build_phase(self):
        super().build_phase()

    def connect_phase(self):
        super().connect_phase()

    def write_wr(self, item):
        """Write port callback for write transactions"""
        if item.op == FifoOp.WRITE and item.success:
            self.fifo_model.append(item.data)
            self.wr_count += 1
            self.logger.info(
                f"SB: Write: data=0x{item.data:x}, queue_size={len(self.fifo_model)}"
            )

    def write_rd(self, item):
        """Write port callback for read transactions"""
        if item.op == FifoOp.READ and item.success:
            if len(self.fifo_model) > 0:
                expected = self.fifo_model.pop(0)
                self.rd_count += 1
                if item.read_data == expected:
                    self.logger.info(
                        f"SB: Read OK: data=0x{item.read_data:x}, queue_size={len(self.fifo_model)}"
                    )
                else:
                    self.logger.error(
                        f"SB: Data mismatch! Expected:0x{expected:x} Got:0x{item.read_data:x}"
                    )
                    self.errors += 1
            else:
                self.logger.error("SB: Read from empty FIFO model")
                self.errors += 1

    def report_phase(self):
        """Report phase - print results"""
        self.logger.info(f"\n{'='*50}")
        self.logger.info(f"FIFO VIP Scoreboard Report")
        self.logger.info(f"{'='*50}")
        self.logger.info(f"Total Writes: {self.wr_count}")
        self.logger.info(f"Total Reads: {self.rd_count}")
        self.logger.info(f"Errors: {self.errors}")
        self.logger.info(f"Final Queue Size: {len(self.fifo_model)}")

        if self.errors == 0:
            self.logger.info("*** TEST PASSED ***")
        else:
            self.logger.error(f"*** TEST FAILED - {self.errors} errors ***")
        self.logger.info(f"{'='*50}\n")
