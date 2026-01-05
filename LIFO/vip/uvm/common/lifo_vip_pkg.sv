//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_pkg
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Main package containing all LIFO VIP components
//
//////////////////////////////////////////////////////////////////////////////////

package lifo_vip_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Types and enums defined directly in package
    typedef enum {
        PUSH,
        POP,
        IDLE
    } lifo_op_e;

    typedef enum {
        MASTER,
        SLAVE,
        MONITOR_ONLY
    } lifo_agent_mode_e;

    // Include files in order
    `include "../common/lifo_vip_config.sv"
    `include "../common/lifo_vip_seq_item.sv"
    `include "../agent/lifo_vip_driver.sv"
    `include "../agent/lifo_vip_monitor.sv"
    `include "../agent/lifo_vip_sequencer.sv"
    `include "../agent/lifo_vip_agent.sv"
    `include "../env/lifo_vip_scoreboard.sv"
    `include "../env/lifo_vip_env.sv"
    `include "../sequences/lifo_vip_base_seq.sv"
    `include "../sequences/lifo_vip_push_seq.sv"
    `include "../sequences/lifo_vip_pop_seq.sv"

endpackage
