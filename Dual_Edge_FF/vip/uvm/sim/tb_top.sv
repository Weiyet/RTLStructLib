//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: tb_top
// Description: Top-level testbench for Dual Edge FF VIP
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import deff_vip_pkg::*;

    `include "tests/deff_vip_base_test.sv"
    `include "tests/deff_vip_simple_test.sv"

    logic clk = 0;
    always #12.5 clk = ~clk;  // 40MHz

    deff_vip_if dut_if(clk);

    initial begin
        dut_if.rst_n = 0;
        repeat(5) @(posedge clk);
        dut_if.rst_n = 1;
    end

    dual_edge_ff #(
        .DATA_WIDTH(8),
        .RESET_VALUE(8'h00)
    ) dut (
        .clk(clk),
        .rst_n(dut_if.rst_n),
        .data_in(dut_if.data_in),
        .pos_edge_latch_en(dut_if.pos_edge_latch_en),
        .neg_edge_latch_en(dut_if.neg_edge_latch_en),
        .data_out(dut_if.data_out)
    );

    initial begin
        uvm_config_db#(virtual deff_vip_if)::set(null, "*", "deff_vip_vif", dut_if);
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);
        run_test();
    end

    initial begin
        #100us;
        $finish;
    end

endmodule
