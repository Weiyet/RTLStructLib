//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: tb_top
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Top-level testbench for LIFO VIP
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import lifo_vip_pkg::*;

    // Include test files
    `include "tests/lifo_vip_base_test.sv"
    `include "tests/lifo_vip_simple_test.sv"

    // Clock
    logic clk = 0;

    // Clock generation - MODIFY PERIOD AS NEEDED
    always #10 clk = ~clk;  // 50MHz

    // Interface
    lifo_vip_if dut_if(clk);

    // Reset
    initial begin
        dut_if.rst = 1;
        repeat(5) @(posedge clk);
        dut_if.rst = 0;
    end

    // DUT instantiation - MODIFY FOR YOUR LIFO
    lifo #(
        .DEPTH(12),
        .DATA_WIDTH(8)
    ) dut (
        .clk(clk),
        .rst(dut_if.rst),
        .data_wr(dut_if.data_wr),
        .wr_en(dut_if.wr_en),
        .lifo_full(dut_if.lifo_full),
        .data_rd(dut_if.data_rd),
        .rd_en(dut_if.rd_en),
        .lifo_empty(dut_if.lifo_empty)
    );

    // UVM testbench
    initial begin
        uvm_config_db#(virtual lifo_vip_if)::set(null, "*", "lifo_vip_vif", dut_if);

        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);

        run_test();
    end

    // Timeout
    initial begin
        #50us;
        $finish;
    end

endmodule
