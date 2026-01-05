//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_sequencer
//////////////////////////////////////////////////////////////////////////////////

class ht_vip_sequencer extends uvm_sequencer #(ht_vip_seq_item);
    `uvm_component_utils(ht_vip_sequencer)

    function new(string name = "ht_vip_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
