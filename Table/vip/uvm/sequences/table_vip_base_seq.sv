//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_base_seq
//////////////////////////////////////////////////////////////////////////////////

class table_vip_base_seq extends uvm_sequence #(table_vip_seq_item);
    `uvm_object_utils(table_vip_base_seq)

    function new(string name = "table_vip_base_seq");
        super.new(name);
    endfunction

endclass
