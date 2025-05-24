//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 08:57 PM
// Module Name: fifo_vip_agent
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the FIFO VIP agent.
// 
//////////////////////////////////////////////////////////////////////////////////

class fifo_vip_agent extends uvm_agent;
    `uvm_component_utils(fifo_vip_agent)
    
    fifo_vip_driver driver;
    fifo_vip_monitor monitor;
    fifo_vip_sequencer sequencer;
    
    uvm_analysis_port #(fifo_vip_seq_item) ap;
    
    function new(string name = "fifo_vip_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        monitor = fifo_vip_monitor::type_id::create("monitor", this);
        
        if (is_active == UVM_ACTIVE) begin
            driver = fifo_vip_driver::type_id::create("driver", this);
            sequencer = fifo_vip_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        ap = monitor.ap;
        
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass