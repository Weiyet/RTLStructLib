//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: tb_top
// Description: Top-level testbench for Table VIP
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import table_vip_pkg::*;

    `include "tests/table_vip_base_test.sv"
    `include "tests/table_vip_simple_test.sv"

    logic clk = 0;
    always #12.5 clk = ~clk;  // 40MHz

    table_vip_if dut_if(clk);

    initial begin
        dut_if.rst = 1;
        repeat(5) @(posedge clk);
        @(negedge clk);
        dut_if.rst = 0;
    end

    table_top #(
        .TABLE_SIZE(32),
        .DATA_WIDTH(8),
        .INPUT_RATE(2),
        .OUTPUT_RATE(2)
    ) dut (
        .clk(clk),
        .rst(dut_if.rst),
        .wr_en(dut_if.wr_en),
        .rd_en(dut_if.rd_en),
        .index_wr(dut_if.index_wr),
        .index_rd(dut_if.index_rd),
        .data_wr(dut_if.data_wr),
        .data_rd(dut_if.data_rd)
    );

    initial begin
        uvm_config_db#(virtual table_vip_if)::set(null, "*", "table_vip_vif", dut_if);

        run_test();
    end

    initial begin
        int timeout_cycles = 100000;
        void'($value$plusargs("TB_TIMEOUT_CYCLES=%d", timeout_cycles));
        repeat (timeout_cycles) @(posedge clk);
        `uvm_fatal("TIMEOUT", "UVM test did not complete")
    end

endmodule
