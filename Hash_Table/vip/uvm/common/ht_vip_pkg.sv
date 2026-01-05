//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_pkg
//////////////////////////////////////////////////////////////////////////////////

package ht_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef enum bit [1:0] {
        INSERT = 2'b00,
        DELETE = 2'b01,
        SEARCH = 2'b10,
        IDLE   = 2'b11
    } ht_op_e;

    `include "ht_vip_config.sv"
    `include "ht_vip_seq_item.sv"
    `include "ht_vip_sequencer.sv"
    `include "ht_vip_driver.sv"
    `include "ht_vip_monitor.sv"
    `include "ht_vip_agent.sv"
    `include "ht_vip_scoreboard.sv"
    `include "ht_vip_env.sv"
    `include "ht_vip_base_seq.sv"

endpackage
