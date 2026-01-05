//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_sequencer
//////////////////////////////////////////////////////////////////////////////////

class sll_vip_sequencer extends uvm_sequencer #(sll_vip_seq_item);
    `uvm_component_utils(sll_vip_sequencer)

    function new(string name = "sll_vip_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
