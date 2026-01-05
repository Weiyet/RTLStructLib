//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_sequencer
//////////////////////////////////////////////////////////////////////////////////

class deff_vip_sequencer extends uvm_sequencer #(deff_vip_seq_item);
    `uvm_component_utils(deff_vip_sequencer)

    function new(string name = "deff_vip_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
