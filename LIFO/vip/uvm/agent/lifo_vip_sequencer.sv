//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_sequencer
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Sequencer for LIFO VIP - coordinates sequences
//
//////////////////////////////////////////////////////////////////////////////////

class lifo_vip_sequencer extends uvm_sequencer #(lifo_vip_seq_item);
    `uvm_component_utils(lifo_vip_sequencer)

    function new(string name = "lifo_vip_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
