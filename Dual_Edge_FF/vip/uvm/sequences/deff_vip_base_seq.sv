//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_base_seq
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_base_seq extends uvm_sequence #(deff_vip_seq_item);
    `uvm_object_utils(deff_vip_base_seq)

    function new(string name = "deff_vip_base_seq");
        super.new(name);
    endfunction

endclass
