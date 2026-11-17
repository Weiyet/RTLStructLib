interface priority_vip_if(input logic clk);
    timeunit 1ns;
    timeprecision 1ps;
    import priority_vip_params_pkg::*;
    logic rst, req_valid, req_ready, rsp_valid, rsp_ready, rsp_error;
    logic [1:0] req_op;
    logic [PRIORITY_WIDTH-1:0] req_priority, rsp_priority;
    logic [DATA_WIDTH-1:0] req_data, rsp_data;
    logic [COUNT_WIDTH-1:0] count;
    logic full, empty;

    // Pre-edge sampling observes accepted transfers, not NBA-updated flags.
    clocking mon_cb @(posedge clk);
        default input #1step;
        input rst, req_valid, req_ready, req_op, req_priority, req_data;
        input rsp_valid, rsp_ready, rsp_error, rsp_priority, rsp_data;
        input count, full, empty;
    endclocking
endinterface
