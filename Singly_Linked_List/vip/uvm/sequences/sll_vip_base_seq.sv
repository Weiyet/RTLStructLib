//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_base_seq
//////////////////////////////////////////////////////////////////////////////////

class sll_vip_base_seq extends uvm_sequence #(sll_vip_seq_item);
    `uvm_object_utils(sll_vip_base_seq)

    function new(string name = "sll_vip_base_seq");
        super.new(name);
    endfunction

endclass
