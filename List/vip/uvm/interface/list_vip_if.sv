//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: list_vip_if
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Interface for List VIP with clocking blocks
//
//////////////////////////////////////////////////////////////////////////////////

interface list_vip_if(input logic clk);

    // Signals matching your List DUT (list.sv lines 20-31)
    logic rst;
    logic [2:0] op_sel;
    logic op_en;
    logic [31:0] data_in;      // Parameterizable width
    logic [15:0] index_in;     // Parameterizable width
    logic [47:0] data_out;     // LENGTH_WIDTH + DATA_WIDTH
    logic op_done;
    logic op_in_progress;
    logic op_error;
    logic [3:0] len;           // Current list length

    // Clocking block for driver
    clocking cb @(posedge clk);
        output op_sel, op_en, data_in, index_in;
        input data_out, op_done, op_in_progress, op_error, len;
    endclocking

    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        input op_sel, op_en, data_in, index_in;
        input data_out, op_done, op_in_progress, op_error, len;
    endclocking

    // Modports
    modport drv (clocking cb, input rst);
    modport mon (clocking mon_cb, input rst);

endinterface
