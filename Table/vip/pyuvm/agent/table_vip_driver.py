"""Table VIP Driver"""
from pyuvm import uvm_driver
from cocotb.triggers import RisingEdge
from ..common.table_vip_seq_item import TableVipSeqItem
from ..common import TableOp

class TableVipDriver(uvm_driver):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.dut = None
        self.cfg = None

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
        # Initialize signals
        self.dut.wr_en.value = 0
        self.dut.rd_en.value = 0
        self.dut.index_wr.value = 0
        self.dut.index_rd.value = 0
        self.dut.data_wr.value = 0

        while True:
            item = await self.seq_item_port.get_next_item()
            await self.drive_item(item)
            self.seq_item_port.item_done()

    async def drive_item(self, item):
        """Drive transaction to DUT"""
        if item.op == TableOp.WRITE:
            await self.drive_write(item)
        else:
            await self.drive_read(item)

    async def drive_write(self, item):
        """Drive WRITE operation"""
        await RisingEdge(self.dut.clk)

        # Pack write enables (2 bits)
        wr_en_val = (item.wr_en[1] << 1) | item.wr_en[0]
        self.dut.wr_en.value = wr_en_val
        self.dut.rd_en.value = 0

        # Pack write indices (10 bits: [9:5] for idx[1], [4:0] for idx[0])
        index_wr_val = (item.index_wr[1] << 5) | item.index_wr[0]
        self.dut.index_wr.value = index_wr_val

        # Pack write data (16 bits: [15:8] for data[1], [7:0] for data[0])
        data_wr_val = (item.data_wr[1] << 8) | item.data_wr[0]
        self.dut.data_wr.value = data_wr_val

        await RisingEdge(self.dut.clk)
        self.dut.wr_en.value = 0

        self.logger.debug(f"WRITE: wr_en=0x{wr_en_val:x} idx[0]={item.index_wr[0]} "
                         f"data[0]=0x{item.data_wr[0]:x} idx[1]={item.index_wr[1]} "
                         f"data[1]=0x{item.data_wr[1]:x}")

    async def drive_read(self, item):
        """Drive READ operation"""
        await RisingEdge(self.dut.clk)
        self.dut.rd_en.value = 1
        self.dut.wr_en.value = 0

        # Pack read indices (10 bits: [9:5] for idx[1], [4:0] for idx[0])
        index_rd_val = (item.index_rd[1] << 5) | item.index_rd[0]
        self.dut.index_rd.value = index_rd_val

        await RisingEdge(self.dut.clk)

        # Unpack read data
        data_rd_val = int(self.dut.data_rd.value)
        item.data_rd[0] = data_rd_val & 0xFF
        item.data_rd[1] = (data_rd_val >> 8) & 0xFF

        self.dut.rd_en.value = 0

        self.logger.debug(f"READ: idx[0]={item.index_rd[0]} data[0]=0x{item.data_rd[0]:x} "
                         f"idx[1]={item.index_rd[1]} data[1]=0x{item.data_rd[1]:x}")
