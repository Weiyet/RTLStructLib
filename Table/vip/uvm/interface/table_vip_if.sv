//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_if
//////////////////////////////////////////////////////////////////////////////////

interface table_vip_if(input logic clk);
    logic rst;
    logic [1:0] wr_en;
    logic rd_en;
    logic [9:0] index_wr;  // 2 x 5-bit indices
    logic [9:0] index_rd;  // 2 x 5-bit indices
    logic [15:0] data_wr;  // 2 x 8-bit data
    logic [15:0] data_rd;  // 2 x 8-bit data

    clocking cb @(posedge clk);
        default input #1step output #1ns;
        output wr_en;
        output rd_en;
        output index_wr;
        output index_rd;
        output data_wr;
        input data_rd;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input wr_en;
        input rd_en;
        input index_wr;
        input index_rd;
        input data_wr;
        input data_rd;
    endclocking

    modport driver(clocking cb, output rst);
    modport monitor(clocking mon_cb, input rst);

endinterface
