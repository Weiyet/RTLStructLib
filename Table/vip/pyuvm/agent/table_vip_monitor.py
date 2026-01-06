"""Table VIP Monitor"""
from pyuvm import uvm_monitor
from cocotb.triggers import RisingEdge
from ..common.table_vip_seq_item import TableVipSeqItem
from ..common import TableOp

class TableVipMonitor(uvm_monitor):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None
        from pyuvm import uvm_analysis_port
        self.ap = uvm_analysis_port("ap", self)

    def build_phase(self):
        super().build_phase()
        from pyuvm import ConfigDB
        arr = []
        if not ConfigDB().get(self, "", "table_vip_dut", arr):
            self.logger.critical("No DUT found in ConfigDB!")
        else:
            self.dut = arr[0]

        arr = []
        if not ConfigDB().get(self, "", "table_vip_cfg", arr):
            self.logger.critical("No config found in ConfigDB!")
        else:
            self.cfg = arr[0]

    async def run_phase(self):
        while True:
            await RisingEdge(self.dut.clk)

            wr_en_val = int(self.dut.wr_en.value)
            rd_en_val = int(self.dut.rd_en.value)

            # Detect write operation
            if wr_en_val != 0:
                item = TableVipSeqItem("item")
                item.op = TableOp.WRITE
                item.wr_en = [wr_en_val & 1, (wr_en_val >> 1) & 1]
                item.rd_en = 0

                # Unpack write indices
                index_wr_val = int(self.dut.index_wr.value)
                item.index_wr[0] = index_wr_val & 0x1F
                item.index_wr[1] = (index_wr_val >> 5) & 0x1F

                # Unpack write data
                data_wr_val = int(self.dut.data_wr.value)
                item.data_wr[0] = data_wr_val & 0xFF
                item.data_wr[1] = (data_wr_val >> 8) & 0xFF

                self.ap.write(item)
                self.logger.debug(f"Observed {item}")

            # Detect read operation
            if rd_en_val != 0:
                item = TableVipSeqItem("item")
                item.op = TableOp.READ
                item.rd_en = 1
                item.wr_en = [0, 0]

                # Unpack read indices
                index_rd_val = int(self.dut.index_rd.value)
                item.index_rd[0] = index_rd_val & 0x1F
                item.index_rd[1] = (index_rd_val >> 5) & 0x1F

                await RisingEdge(self.dut.clk)

                # Unpack read data
                data_rd_val = int(self.dut.data_rd.value)
                item.data_rd[0] = data_rd_val & 0xFF
                item.data_rd[1] = (data_rd_val >> 8) & 0xFF

                self.ap.write(item)
                self.logger.debug(f"Observed {item}")
