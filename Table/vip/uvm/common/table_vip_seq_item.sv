//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_seq_item
//////////////////////////////////////////////////////////////////////////////////

class table_vip_seq_item extends uvm_sequence_item;
    `uvm_object_utils(table_vip_seq_item)

    rand table_op_e op;

    // Write operation (supports multiple writes)
    rand bit [1:0] wr_en;
    rand bit [4:0] index_wr[2];  // 2 write indices
    rand bit [7:0] data_wr[2];   // 2 write data

    // Read operation (supports multiple reads)
    rand bit rd_en;
    rand bit [4:0] index_rd[2];  // 2 read indices

    // Read results
    bit [7:0] data_rd[2];  // 2 read data

    constraint valid_op_c {
        op inside {WRITE, READ};
    }

    constraint valid_write_c {
        if (op == WRITE) {
            wr_en != 2'b00;  // At least one write enable
            rd_en == 0;
            foreach(index_wr[i]) {
                index_wr[i] < 32;  // Valid table index
            }
        }
    }

    constraint valid_read_c {
        if (op == READ) {
            rd_en == 1;
            wr_en == 2'b00;
            foreach(index_rd[i]) {
                index_rd[i] < 32;  // Valid table index
            }
        }
    }

    function new(string name = "table_vip_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        string s;
        if (op == WRITE) begin
            s = $sformatf("WRITE: ");
            if (wr_en[0]) s = {s, $sformatf("idx[0]=%0d data[0]=0x%0h ", index_wr[0], data_wr[0])};
            if (wr_en[1]) s = {s, $sformatf("idx[1]=%0d data[1]=0x%0h ", index_wr[1], data_wr[1])};
        end else begin
            s = $sformatf("READ: idx[0]=%0d data[0]=0x%0h idx[1]=%0d data[1]=0x%0h",
                         index_rd[0], data_rd[0], index_rd[1], data_rd[1]);
        end
        return s;
    endfunction

    function void do_copy(uvm_object rhs);
        table_vip_seq_item rhs_;
        if (!$cast(rhs_, rhs))
            `uvm_fatal("DO_COPY", "Cast failed")
        super.do_copy(rhs);
        op = rhs_.op;
        wr_en = rhs_.wr_en;
        rd_en = rhs_.rd_en;
        index_wr = rhs_.index_wr;
        data_wr = rhs_.data_wr;
        index_rd = rhs_.index_rd;
        data_rd = rhs_.data_rd;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        table_vip_seq_item rhs_;
        if (!$cast(rhs_, rhs))
            return 0;
        return (super.do_compare(rhs, comparer) &&
                (op == rhs_.op));
    endfunction

endclass
