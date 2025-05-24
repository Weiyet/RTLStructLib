//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 10:04 PM
// Module Name: fifo_vip_base_test
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the base test for the FIFO VIP.
// 
//////////////////////////////////////////////////////////////////////////////////

class base_test extends uvm_test;
    `uvm_component_utils(base_test)
    
    fifo_vip_env env;
    fifo_vip_config cfg;
    
    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create config - MODIFY FOR YOUR FIFO
        cfg = fifo_vip_config::type_id::create("cfg");
        cfg.DEPTH = 12;        // Change this
        cfg.DATA_WIDTH = 8;    // Change this
        cfg.ASYNC = 1;         // Change this
        cfg.RD_BUFFER = 1;     // Change this
        
        // Set config in database with better field name
        uvm_config_db#(fifo_vip_config)::set(this, "*", "fifo_vip_cfg", cfg);
        
        env = fifo_vip_env::type_id::create("env", this);
    endfunction
    
    function void end_of_elaboration_phase(uvm_phase phase);
        cfg.print_config();
        uvm_top.print_topology();
    endfunction

endclass