//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 08:41 PM
// Module Name: fifo_vip_config
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the configuration class for the FIFO VIP.
// 
//////////////////////////////////////////////////////////////////////////////////

class fifo_vip_config extends uvm_object;
    `uvm_object_utils(fifo_vip_config)
    
    // DUT parameters - CHANGE THESE FOR YOUR FIFO
    int DEPTH = 12;
    int DATA_WIDTH = 8;
    bit ASYNC = 1;
    bit RD_BUFFER = 1;
    
    // VIP control
    bit has_wr_agent = 1;
    bit has_rd_agent = 1;
    bit enable_scoreboard = 1;
    
    // Agent modes
    fifo_agent_mode_e wr_agent_mode = MASTER;
    fifo_agent_mode_e rd_agent_mode = MASTER;
    
    function new(string name = "fifo_vip_config");
        super.new(name);
    endfunction
    
    function void print_config();
        `uvm_info("CFG", $sformatf("DEPTH=%0d, DATA_WIDTH=%0d, ASYNC=%0b, RD_BUFFER=%0b", 
                 DEPTH, DATA_WIDTH, ASYNC, RD_BUFFER), UVM_LOW)
    endfunction

endclass