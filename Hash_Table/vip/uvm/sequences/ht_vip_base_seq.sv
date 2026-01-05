//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_base_seq
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_base_seq extends uvm_sequence #(ht_vip_seq_item);
    `uvm_object_utils(ht_vip_base_seq)

    function new(string name = "ht_vip_base_seq");
        super.new(name);
    endfunction

endclass
