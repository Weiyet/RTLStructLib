//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_seq_item
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Sequence item for List VIP transactions
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_seq_item extends uvm_sequence_item;
    `uvm_object_utils(list_vip_seq_item)

    // Transaction fields
    rand list_op_e op;
    rand bit [31:0] data;
    rand bit [15:0] index;

    // Response fields
    bit [31:0] result_data;    // For READ, FIND_1ST, FIND_ALL, SUM
    bit op_done;
    bit op_in_progress;
    bit op_error;
    int current_len;

    // Config reference
    list_vip_config cfg;

    // Constraints
    constraint op_dist {
        op dist {
            READ := 20,
            INSERT := 30,
            DELETE := 10,
            FIND_1ST := 10,
            FIND_ALL := 5,
            SUM := 10,
            SORT_ASC := 5,
            SORT_DES := 5,
            IDLE := 5
        };
    }

    constraint data_c {
        if (cfg != null) {
            data < (1 << cfg.DATA_WIDTH);
        } else {
            data < 256; // 8-bit default
        }
    }

    constraint index_c {
        if (cfg != null) {
            index < cfg.LENGTH;
        } else {
            index < 8; // default
        }
    }

    function new(string name = "list_vip_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("Op:%s Data:0x%0h Index:%0d Result:0x%0h Done:%0b Error:%0b Len:%0d",
                        op.name(), data, index, result_data, op_done, op_error, current_len);
    endfunction

endclass
