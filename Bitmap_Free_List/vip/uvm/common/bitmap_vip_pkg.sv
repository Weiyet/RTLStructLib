package bitmap_vip_pkg;
    timeunit 1ns;
    timeprecision 1ps;
    import uvm_pkg::*;
    import bitmap_vip_params_pkg::*;
    `include "uvm_macros.svh"
    `include "bitmap_vip_config.sv"
    `include "bitmap_vip_seq_item.sv"
    `include "bitmap_vip_driver.sv"
    `include "bitmap_vip_monitor.sv"
    `include "bitmap_vip_agent.sv"
    `include "bitmap_vip_scoreboard.sv"
    `include "bitmap_vip_env.sv"
    `include "bitmap_vip_sequences.sv"
    `include "bitmap_vip_test.sv"
endpackage
