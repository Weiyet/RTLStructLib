//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 10:37 PM
// Module Name: fifo_vip_pkg
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains all the components of the FIFO VIP.
// 
//////////////////////////////////////////////////////////////////////////////////

package fifo_vip_pkg;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Types and enums defined directly in package
    typedef enum {
        WRITE,
        READ,
        IDLE
    } fifo_op_e;
    
    typedef enum {
        MASTER,
        SLAVE,
        MONITOR_ONLY
    } fifo_agent_mode_e;
    
    // Include files in order
    `include "../src/fifo_vip_config.sv"
    `include "../src/fifo_vip_seq_item.sv"
    `include "../agent/fifo_vip_driver.sv"
    `include "../agent/fifo_vip_monitor.sv"
    `include "../agent/fifo_vip_sequencer.sv"
    `include "../agent/fifo_vip_agent.sv"
    `include "../env/fifo_vip_scoreboard.sv"
    `include "../env/fifo_vip_env.sv"
    `include "../sequences/fifo_vip_base_seq.sv"
    `include "../sequences/fifo_vip_write_req_seq.sv"
    `include "../sequences/fifo_vip_read_req_seq.sv"
    
endpackage