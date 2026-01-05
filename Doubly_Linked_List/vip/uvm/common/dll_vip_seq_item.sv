//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_seq_item
// Description: Sequence item for Doubly Linked List VIP
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_seq_item extends uvm_sequence_item;
    `uvm_object_utils(dll_vip_seq_item)

    rand dll_op_e op;
    rand bit [31:0] data;
    rand bit [15:0] addr;

    bit [31:0] result_data;
    bit [15:0] result_pre_addr;
    bit [15:0] result_next_addr;
    bit op_done;
    bit fault;
    int current_len;
    bit [15:0] current_head;
    bit [15:0] current_tail;

    dll_vip_config cfg;

    constraint op_dist {
        op dist {
            READ_ADDR := 20,
            INSERT_AT_ADDR := 20,
            INSERT_AT_INDEX := 20,
            DELETE_VALUE := 10,
            DELETE_AT_ADDR := 15,
            DELETE_AT_INDEX := 10,
            IDLE := 5
        };
    }

    function new(string name = "dll_vip_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("Op:%s Data:0x%0h Addr:%0d Result:0x%0h Done:%0b Fault:%0b Len:%0d",
                        op.name(), data, addr, result_data, op_done, fault, current_len);
    endfunction

endclass
