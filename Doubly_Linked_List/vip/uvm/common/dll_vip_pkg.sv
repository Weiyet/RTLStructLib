//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: dll_vip_pkg
// Description: Main package for Doubly Linked List VIP
//////////////////////////////////////////////////////////////////////////////////

package dll_vip_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Operations matching DUT (doubly_linked_list.sv)
    typedef enum bit [2:0] {
        READ_ADDR          = 3'b000,  // Read data at address
        INSERT_AT_ADDR     = 3'b001,  // Insert at address
        DELETE_VALUE       = 3'b010,  // Delete by value
        DELETE_AT_ADDR     = 3'b011,  // Delete at address
        INSERT_AT_INDEX    = 3'b101,  // Insert at index
        DELETE_AT_INDEX    = 3'b111,  // Delete at index
        IDLE               = 3'b100
    } dll_op_e;

    `include "../common/dll_vip_config.sv"
    `include "../common/dll_vip_seq_item.sv"
    `include "../agent/dll_vip_driver.sv"
    `include "../agent/dll_vip_monitor.sv"
    `include "../agent/dll_vip_sequencer.sv"
    `include "../agent/dll_vip_agent.sv"
    `include "../env/dll_vip_scoreboard.sv"
    `include "../env/dll_vip_env.sv"
    `include "../sequences/dll_vip_base_seq.sv"
    `include "../sequences/dll_vip_insert_seq.sv"
    `include "../sequences/dll_vip_read_seq.sv"
    `include "../sequences/dll_vip_delete_seq.sv"

endpackage
