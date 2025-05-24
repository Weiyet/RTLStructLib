//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 10:04 PM
// Module Name: fifo_vip_base_test
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the base test for the FIFO VIP.
// 
//////////////////////////////////////////////////////////////////////////////////
    
class simple_test extends base_test;
    `uvm_component_utils(simple_test)
    
    function new(string name = "simple_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        fifo_vip_write_req_seq wr_seq;
        fifo_vip_read_req_seq rd_seq;
        
        phase.raise_objection(this);
        
        // Write some data
        wr_seq = fifo_vip_write_req_seq::type_id::create("wr_seq");
        wr_seq.num_writes = 8;
        wr_seq.start(env.get_wr_sequencer());
        
        #200ns;
        
        // Read it back
        rd_seq = fifo_vip_read_req_seq::type_id::create("rd_seq");
        rd_seq.num_reads = 8;
        rd_seq.start(env.get_rd_sequencer());
        
        #200ns;
        phase.drop_objection(this);
    endtask

endclass