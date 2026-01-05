//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: deff_vip_if
//////////////////////////////////////////////////////////////////////////////////

interface deff_vip_if(input logic clk);
    logic rst_n;
    logic [7:0] data_in;
    logic [7:0] pos_edge_latch_en;
    logic [7:0] neg_edge_latch_en;
    logic [7:0] data_out;

    clocking cb @(posedge clk);
        default input #1step output #1ns;
        output data_in;
        output pos_edge_latch_en;
        output neg_edge_latch_en;
        input data_out;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input data_in;
        input pos_edge_latch_en;
        input neg_edge_latch_en;
        input data_out;
    endclocking

    // Monitor on negative edge for dual-edge verification
    clocking mon_neg_cb @(negedge clk);
        default input #1step;
        input data_in;
        input pos_edge_latch_en;
        input neg_edge_latch_en;
        input data_out;
    endclocking

    modport driver(clocking cb, output rst_n);
    modport monitor(clocking mon_cb, clocking mon_neg_cb, input rst_n);

endinterface
