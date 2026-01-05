//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_sequencer
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Sequencer for List VIP - coordinates sequences
//
//////////////////////////////////////////////////////////////////////////////////

class list_vip_sequencer extends uvm_sequencer #(list_vip_seq_item);
    `uvm_component_utils(list_vip_sequencer)

    function new(string name = "list_vip_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
