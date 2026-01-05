//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_pkg
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Main package containing all List VIP components
//
//////////////////////////////////////////////////////////////////////////////////

package list_vip_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Types and enums matching DUT operations (list.sv line 37-44)
    typedef enum bit [2:0] {
        READ        = 3'b000,  // Read data at index
        INSERT      = 3'b001,  // Insert data at index
        FIND_ALL    = 3'b010,  // Find all indices of value
        FIND_1ST    = 3'b011,  // Find first index of value
        SUM         = 3'b100,  // Sum all elements
        SORT_ASC    = 3'b101,  // Sort ascending
        SORT_DES    = 3'b110,  // Sort descending
        DELETE      = 3'b111,  // Delete element at index
        IDLE        = 3'b000   // No operation (same as READ for encoding)
    } list_op_e;

    typedef enum {
        MASTER,
        SLAVE,
        MONITOR_ONLY
    } list_agent_mode_e;

    // Include files in dependency order
    `include "../common/list_vip_config.sv"
    `include "../common/list_vip_seq_item.sv"
    `include "../agent/list_vip_driver.sv"
    `include "../agent/list_vip_monitor.sv"
    `include "../agent/list_vip_sequencer.sv"
    `include "../agent/list_vip_agent.sv"
    `include "../env/list_vip_scoreboard.sv"
    `include "../env/list_vip_env.sv"
    `include "../sequences/list_vip_base_seq.sv"
    `include "../sequences/list_vip_insert_seq.sv"
    `include "../sequences/list_vip_read_seq.sv"
    `include "../sequences/list_vip_delete_seq.sv"
    `include "../sequences/list_vip_find_seq.sv"
    `include "../sequences/list_vip_sort_seq.sv"
    `include "../sequences/list_vip_sum_seq.sv"

endpackage
