//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 09:27 PM
// Module Name: fifo_vip_base_seq	
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This sequence serves as a base class for FIFO VIP sequences.
// 
//////////////////////////////////////////////////////////////////////////////////

class fifo_vip_base_seq extends uvm_sequence #(fifo_vip_seq_item);
    `uvm_object_utils(fifo_vip_base_seq)
    
    fifo_vip_config cfg;
    
    function new(string name = "fifo_vip_base_seq");
        super.new(name);
    endfunction
    
    task pre_body();
        if (!uvm_config_db#(fifo_vip_config)::get(m_sequencer, "", "fifo_vip_cfg", cfg)) begin
            `uvm_warning("SEQ", "No config found")
        end
    endtask

endclass