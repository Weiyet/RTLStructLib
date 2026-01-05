//////////////////////////////////////////////////////////////////////////////////
//
// Create Date: 01/04/2026
// Module Name: tb_top
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: Top-level testbench for List VIP
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import list_vip_pkg::*;

    // Include test files
    `include "tests/list_vip_base_test.sv"
    `include "tests/list_vip_simple_test.sv"

    // Clock
    logic clk = 0;

    // Clock generation - MODIFY PERIOD AS NEEDED
    always #12.5 clk = ~clk;  // 40MHz (25ns period)

    // Interface
    list_vip_if dut_if(clk);

    // Reset
    initial begin
        dut_if.rst = 1;
        repeat(5) @(posedge clk);
        dut_if.rst = 0;
    end

    // DUT instantiation - MODIFY FOR YOUR LIST
    list #(
        .DATA_WIDTH(8),
        .LENGTH(8),
        .SUM_METHOD(0)
    ) dut (
        .clk(clk),
        .rst(dut_if.rst),
        .op_sel(dut_if.op_sel),
        .op_en(dut_if.op_en),
        .data_in(dut_if.data_in[7:0]),
        .index_in(dut_if.index_in[2:0]),
        .data_out(dut_if.data_out[10:0]),
        .op_done(dut_if.op_done),
        .op_in_progress(dut_if.op_in_progress),
        .op_error(dut_if.op_error),
        .len(dut_if.len)
    );

    // UVM testbench
    initial begin
        uvm_config_db#(virtual list_vip_if)::set(null, "*", "list_vip_vif", dut_if);

        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);

        run_test();
    end

    // Timeout
    initial begin
        #100us;
        $finish;
    end

endmodule
