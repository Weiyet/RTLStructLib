//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_seq_item
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Sequence item for LIFO VIP transactions
//
//////////////////////////////////////////////////////////////////////////////////

class lifo_vip_seq_item extends uvm_sequence_item;
    `uvm_object_utils(lifo_vip_seq_item)

    // Transaction fields
    rand lifo_op_e op;
    rand bit [31:0] data;

    // Response fields
    bit [31:0] read_data;
    bit full;
    bit empty;
    bit success;

    // Config reference
    lifo_vip_config cfg;

    // Simple constraints
    constraint op_dist {
        op dist {PUSH := 50, POP := 50};
    }

    constraint data_c {
        if (cfg != null) {
            data < (1 << cfg.DATA_WIDTH);
        } else {
            data < 256; // 8-bit default
        }
    }

    function new(string name = "lifo_vip_seq_item");
        super.new(name);
        success = 1;
    endfunction

    function string convert2string();
        return $sformatf("Op:%s Data:0x%0h ReadData:0x%0h Full:%0b Empty:%0b Success:%0b",
                        op.name(), data, read_data, full, empty, success);
    endfunction

endclass
