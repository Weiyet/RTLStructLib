//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_pkg
//////////////////////////////////////////////////////////////////////////////////

package table_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef enum bit {
        WRITE = 1'b0,
        READ  = 1'b1
    } table_op_e;

    `include "table_vip_config.sv"
    `include "table_vip_seq_item.sv"
    `include "table_vip_sequencer.sv"
    `include "table_vip_driver.sv"
    `include "table_vip_monitor.sv"
    `include "table_vip_agent.sv"
    `include "table_vip_scoreboard.sv"
    `include "table_vip_env.sv"
    `include "table_vip_base_seq.sv"

endpackage
