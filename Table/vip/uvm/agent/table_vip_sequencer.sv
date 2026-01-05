//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_sequencer
//////////////////////////////////////////////////////////////////////////////////

class table_vip_sequencer extends uvm_sequencer #(table_vip_seq_item);
    `uvm_component_utils(table_vip_sequencer)

    function new(string name = "table_vip_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
