//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 09:25 PM
// Module Name: fifo_vip_sequencer
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains all the components of the FIFO VIP.
// 
//////////////////////////////////////////////////////////////////////////////////


class fifo_vip_sequencer extends uvm_sequencer #(fifo_vip_seq_item);
    `uvm_component_utils(fifo_vip_sequencer)
    
    function new(string name = "fifo_vip_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass