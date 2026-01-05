//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: sll_vip_if
//////////////////////////////////////////////////////////////////////////////////

interface sll_vip_if(input logic clk);

    logic rst;
    logic [7:0] data_in;
    logic [3:0] addr_in;
    logic [2:0] op;
    logic op_start;
    logic op_done;
    logic [7:0] data_out;
    logic [3:0] next_node_addr;  // Only next, no prev
    logic [3:0] length;
    logic [3:0] head;
    logic [3:0] tail;
    logic full;
    logic empty;
    logic fault;

    clocking cb @(posedge clk);
        output data_in, addr_in, op, op_start;
        input op_done, data_out, next_node_addr;
        input length, head, tail, full, empty, fault;
    endclocking

    clocking mon_cb @(posedge clk);
        input data_in, addr_in, op, op_start;
        input op_done, data_out, next_node_addr;
        input length, head, tail, full, empty, fault;
    endclocking

    modport drv (clocking cb, input rst);
    modport mon (clocking mon_cb, input rst);

endinterface
