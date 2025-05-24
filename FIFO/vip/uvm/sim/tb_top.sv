//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/24/2024 03:37 PM
// Last Update Date: 05/24/2024 09:04 PM
// Module Name: tb_top
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: This is the top-level testbench for the FIFO VIP.
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import fifo_vip_pkg::*;
    
    // Clocks
    logic wr_clk = 0;
    logic rd_clk = 0;
    
    // Clock generation - MODIFY PERIODS AS NEEDED
    always #10 wr_clk = ~wr_clk;  // 50MHz
    always #16 rd_clk = ~rd_clk;  // 31.25MHz
    
    // Interface
    fifo_vip_if dut_if(wr_clk, rd_clk);
    
    // Reset
    initial begin
        dut_if.rst = 1;
        repeat(5) @(posedge wr_clk);
        dut_if.rst = 0;
    end
    
    // DUT instantiation - MODIFY FOR YOUR FIFO
    fifo #(
        .DEPTH(12),
        .DATA_WIDTH(8),
        .ASYNC(1),
        .RD_BUFFER(1)
    ) dut (
        .rd_clk(rd_clk),
        .wr_clk(wr_clk),
        .rst(dut_if.rst),
        .data_wr(dut_if.data_wr),
        .wr_en(dut_if.wr_en),
        .fifo_full(dut_if.fifo_full),
        .data_rd(dut_if.data_rd),
        .rd_en(dut_if.rd_en),
        .fifo_empty(dut_if.fifo_empty)
    );
    
    // UVM testbench
    initial begin
        uvm_config_db#(virtual fifo_vip_if)::set(null, "*", "fifo_vip_vif", dut_if);
        
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