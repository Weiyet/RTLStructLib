//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_seq_item
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_seq_item extends uvm_sequence_item;
    `uvm_object_utils(ht_vip_seq_item)

    rand ht_op_e op;
    rand bit [31:0] key;
    rand bit [31:0] value;

    bit [31:0] result_value;
    bit op_done;
    bit op_error;
    bit [3:0] collision_count;

    constraint valid_op_c {
        op inside {INSERT, DELETE, SEARCH};
    }

    constraint valid_key_c {
        key != 0;
    }

    function new(string name = "ht_vip_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("op=%s key=0x%0h value=0x%0h result=0x%0h done=%0b error=%0b collisions=%0d",
                        op.name(), key, value, result_value, op_done, op_error, collision_count);
    endfunction

    function void do_copy(uvm_object rhs);
        ht_vip_seq_item rhs_;
        if (!$cast(rhs_, rhs))
            `uvm_fatal("DO_COPY", "Cast failed")
        super.do_copy(rhs);
        op = rhs_.op;
        key = rhs_.key;
        value = rhs_.value;
        result_value = rhs_.result_value;
        op_done = rhs_.op_done;
        op_error = rhs_.op_error;
        collision_count = rhs_.collision_count;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        ht_vip_seq_item rhs_;
        if (!$cast(rhs_, rhs))
            return 0;
        return (super.do_compare(rhs, comparer) &&
                (op == rhs_.op) &&
                (key == rhs_.key) &&
                (value == rhs_.value));
    endfunction

endclass
