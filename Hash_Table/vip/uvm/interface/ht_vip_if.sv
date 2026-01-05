//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: ht_vip_if
//////////////////////////////////////////////////////////////////////////////////

interface ht_vip_if(input logic clk);
    logic rst;
    logic [31:0] key_in;
    logic [31:0] value_in;
    logic [1:0] op_sel;
    logic op_en;
    logic [31:0] value_out;
    logic op_done;
    logic op_error;
    logic [3:0] collision_count;

    clocking cb @(posedge clk);
        default input #1step output #1ns;
        output key_in;
        output value_in;
        output op_sel;
        output op_en;
        input value_out;
        input op_done;
        input op_error;
        input collision_count;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input key_in;
        input value_in;
        input op_sel;
        input op_en;
        input value_out;
        input op_done;
        input op_error;
        input collision_count;
    endclocking

    modport driver(clocking cb, output rst);
    modport monitor(clocking mon_cb, input rst);

endinterface
