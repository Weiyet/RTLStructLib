//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: lifo_vip_if
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Interface for LIFO VIP with clocking blocks
//
//////////////////////////////////////////////////////////////////////////////////

interface lifo_vip_if(input logic clk);

    // Signals matching your LIFO
    logic rst;
    logic [7:0] data_wr;
    logic wr_en;
    logic lifo_full;
    logic [7:0] data_rd;
    logic rd_en;
    logic lifo_empty;

    // Clocking block for driver
    clocking cb @(posedge clk);
        output data_wr, wr_en, rd_en;
        input data_rd, lifo_full, lifo_empty;
    endclocking

    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        input data_wr, wr_en, rd_en;
        input data_rd, lifo_full, lifo_empty;
    endclocking

    // Modports
    modport drv (clocking cb, input rst);
    modport mon (clocking mon_cb, input rst);

endinterface
