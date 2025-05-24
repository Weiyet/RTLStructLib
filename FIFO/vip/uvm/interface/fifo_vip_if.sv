//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 09:28 PM
// Module Name: fifo_vip_if
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This package contains the FIFO VIP interface.
// 
//////////////////////////////////////////////////////////////////////////////////


interface fifo_vip_if(input logic wr_clk, input logic rd_clk);

    // Signals matching your FIFO
    logic rst;
    logic [7:0] data_wr;
    logic wr_en;
    logic fifo_full;
    logic [7:0] data_rd;
    logic rd_en;
    logic fifo_empty;
    
    // Simple clocking blocks
    clocking wr_cb @(posedge wr_clk);
        output data_wr, wr_en;
        input fifo_full;
    endclocking
    
    clocking rd_cb @(posedge rd_clk);
        output rd_en;
        input data_rd, fifo_empty;
    endclocking
    
    // Modports
    modport wr_drv (clocking wr_cb, input rst);
    modport rd_drv (clocking rd_cb, input rst);

endinterface