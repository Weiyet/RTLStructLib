//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_sequencer
//////////////////////////////////////////////////////////////////////////////////

class dll_vip_sequencer extends uvm_sequencer #(dll_vip_seq_item);
    `uvm_component_utils(dll_vip_sequencer)

    function new(string name = "dll_vip_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
