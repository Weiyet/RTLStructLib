//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_pkg
// Description: Main package for Singly Linked List VIP
//////////////////////////////////////////////////////////////////////////////////

package sll_vip_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Operations matching DUT (singly_linked_list.sv)
    typedef enum bit [2:0] {
        READ_ADDR          = 3'b000,
        INSERT_AT_ADDR     = 3'b001,
        DELETE_VALUE       = 3'b010,
        DELETE_AT_ADDR     = 3'b011,
        INSERT_AT_INDEX    = 3'b101,
        DELETE_AT_INDEX    = 3'b111,
        IDLE               = 3'b100
    } sll_op_e;

    `include "../common/sll_vip_config.sv"
    `include "../common/sll_vip_seq_item.sv"
    `include "../agent/sll_vip_driver.sv"
    `include "../agent/sll_vip_monitor.sv"
    `include "../agent/sll_vip_sequencer.sv"
    `include "../agent/sll_vip_agent.sv"
    `include "../env/sll_vip_scoreboard.sv"
    `include "../env/sll_vip_env.sv"
    `include "../sequences/sll_vip_base_seq.sv"
    `include "../sequences/sll_vip_insert_seq.sv"
    `include "../sequences/sll_vip_read_seq.sv"
    `include "../sequences/sll_vip_delete_seq.sv"

endpackage
