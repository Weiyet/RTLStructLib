//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: tb_top
// Description: Top-level testbench for Hash Table VIP
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import ht_vip_pkg::*;

    `include "tests/ht_vip_base_test.sv"
    `include "tests/ht_vip_simple_test.sv"

    logic clk = 0;
    always #12.5 clk = ~clk;  // 40MHz

    ht_vip_if dut_if(clk);

    initial begin
        dut_if.rst = 1;
        repeat(5) @(posedge clk);
        dut_if.rst = 0;
    end

    hash_table #(
        .KEY_WIDTH(32),
        .VALUE_WIDTH(32),
        .TOTAL_INDEX(8),
        .CHAINING_SIZE(4),
        .COLLISION_METHOD("MULTI_STAGE_CHAINING"),
        .HASH_ALGORITHM("MODULUS")
    ) dut (
        .clk(clk),
        .rst(dut_if.rst),
        .key_in(dut_if.key_in),
        .value_in(dut_if.value_in),
        .op_sel(dut_if.op_sel),
        .op_en(dut_if.op_en),
        .value_out(dut_if.value_out),
        .op_done(dut_if.op_done),
        .op_error(dut_if.op_error),
        .collision_count(dut_if.collision_count)
    );

    initial begin
        uvm_config_db#(virtual ht_vip_if)::set(null, "*", "ht_vip_vif", dut_if);
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);
        run_test();
    end

    initial begin
        #100us;
        $finish;
    end

endmodule
