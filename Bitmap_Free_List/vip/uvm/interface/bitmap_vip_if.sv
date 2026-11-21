interface bitmap_vip_if(input logic clk);
    timeunit 1ns;
    timeprecision 1ps;
    import bitmap_vip_params_pkg::*;
    logic rst, alloc_req, free_req;
    logic [ID_WIDTH-1:0] free_id, alloc_id;
    logic alloc_valid, alloc_error, free_valid, free_error, exhausted, all_free;
    logic [COUNT_WIDTH-1:0] free_count;
    clocking mon_cb @(posedge clk);
        default input #1step;
        input rst, alloc_req, free_req, free_id;
    endclocking
endinterface
