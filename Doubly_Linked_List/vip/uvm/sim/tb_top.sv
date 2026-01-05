//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: tb_top
// Description: Top-level testbench for Doubly Linked List VIP
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import dll_vip_pkg::*;

    `include "tests/dll_vip_base_test.sv"
    `include "tests/dll_vip_simple_test.sv"

    logic clk = 0;
    always #12.5 clk = ~clk;  // 40MHz

    dll_vip_if dut_if(clk);

    initial begin
        dut_if.rst = 1;
        repeat(5) @(posedge clk);
        dut_if.rst = 0;
    end

    doubly_linked_list #(
        .DATA_WIDTH(8),
        .MAX_NODE(8)
    ) dut (
        .clk(clk),
        .rst(dut_if.rst),
        .data_in(dut_if.data_in),
        .addr_in(dut_if.addr_in),
        .op(dut_if.op),
        .op_start(dut_if.op_start),
        .op_done(dut_if.op_done),
        .data_out(dut_if.data_out),
        .pre_node_addr(dut_if.pre_node_addr),
        .next_node_addr(dut_if.next_node_addr),
        .length(dut_if.length),
        .head(dut_if.head),
        .tail(dut_if.tail),
        .full(dut_if.full),
        .empty(dut_if.empty),
        .fault(dut_if.fault)
    );

    initial begin
        uvm_config_db#(virtual dll_vip_if)::set(null, "*", "dll_vip_vif", dut_if);
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);
        run_test();
    end

    initial begin
        #100us;
        $finish;
    end

endmodule
