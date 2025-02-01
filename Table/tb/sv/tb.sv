`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/05/2024 03:37:34 PM
// Last Update Date: 01/02/2024 10:37:12 AM
// Module Name: tb
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: 1. table_write_random() --> table_read_compare()
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb(
);
    parameter TABLE_SIZE = 32;
    parameter DATA_WIDTH = 8;
    parameter INPUT_RATE = 2;
    parameter OUTPUT_RATE = 2;
    parameter TB_CLK_PERIOD = 100;
    parameter TB_TEST_WEIGHT = 1; 
    parameter TB_SIM_TIMEOUT = 30; //ms.

    localparam MAX_DATA = 2**8 - 1;
    localparam INDEX_WIDTH = $clog2(TABLE_SIZE-1);

    bit [DATA_WIDTH-1:0] table_expected [TABLE_SIZE];
    integer index_queue[$];

    reg clk=0;
    reg rst=0;
    reg wr_en=0;
    reg rd_en=0;
    reg [INPUT_RATE*$clog2(TABLE_SIZE)-1:0] index_wr=0;   
    reg [OUTPUT_RATE*$clog2(TABLE_SIZE)-1:0] index_rd=0;
    reg [INPUT_RATE*DATA_WIDTH-1:0] data_wr=0;
    wire [OUTPUT_RATE*DATA_WIDTH-1:0] data_rd;

    reg [DATA_WIDTH-1:0] data_wr_rand;
    reg [$clog2(TABLE_SIZE)-1:0] index_wr_rand;

    integer err_cnt = 0;

    `ifdef XILINX_GLS
        glbl glbl (); // for Xilinx GLS
    `endif

    table_top #(
        .TABLE_SIZE(TABLE_SIZE), 
        .DATA_WIDTH(DATA_WIDTH),
        .INPUT_RATE(INPUT_RATE), 
        .OUTPUT_RATE(OUTPUT_RATE)) DUT (
            /*input wire*/ .clk(clk),
            /*input wire*/ .rst(rst), 
            /*input wire*/ .wr_en(wr_en),
            /*input wire*/ .rd_en(rd_en),
            /*input wire [INPUT_RATE*$clog2(TABLE_SIZE)-1:0]*/ .index_wr(index_wr),
            /*input wire [OUTPUT_RATE*$clog2(TABLE_SIZE)-1:0]*/ .index_rd(index_rd),
            /*input wire [INPUT_RATE*DATA_WIDTH-1:0]*/ .data_wr(data_wr),
            /*output reg [OUTPUT_RATE*DATA_WIDTH-1:0]*/ .data_rd(data_rd));

    always #(TB_CLK_PERIOD>>1) clk = ~clk;

    task table_write_random (input integer count);
        for (int i=0; i<count; i=i+1) begin
            @(posedge(clk)) begin
                #1;
                for (int j=1; j<=INPUT_RATE; j=j+1) begin
                    data_wr_rand = $urandom_range(0,MAX_DATA);
                    index_wr_rand = $urandom_range(0,TABLE_SIZE-1);
                    data_wr[j*DATA_WIDTH-1 -: DATA_WIDTH] = data_wr_rand;
                    index_wr[j*INDEX_WIDTH-1 -:INDEX_WIDTH] = index_wr_rand;
                    table_expected[index_wr_rand] = data_wr_rand;
                    index_queue.push_back(index_wr_rand);
                    $display("%0t table_write_random: Data %0d is written to index %0d", $realtime, data_wr_rand, index_wr_rand);
                end
                wr_en <= 1;
            end
        end
        @(posedge(clk))
        #1; wr_en <= 0;
    endtask

    integer setup_done = 0;

    bit [INDEX_WIDTH-1:0] index_target;
    integer index_temp[$];

    task table_read_compare();
        setup_done = 0;
        while($size(index_queue) != 0) begin
            @(posedge(clk)) begin
                #1;
                rd_en <= 1;
                for (int j=0; j<OUTPUT_RATE; j=j+1) begin
                    index_target = index_queue.pop_front();
                    index_rd[(j+1)*INDEX_WIDTH-1 -: INDEX_WIDTH] = index_target; 
                    index_temp.push_back(index_target);
                    if(setup_done) begin
                        index_target = index_temp.pop_front();
                        if(data_rd[(j+1)*DATA_WIDTH-1 -: DATA_WIDTH] !== table_expected[index_target]) begin
                            err_cnt = err_cnt + 1;
                            $error("%0t table_read_compare: data read at index %0d is incorrect, ACT:%0d , EXP:%0d ", $realtime, index_target, data_rd[(j+1)*DATA_WIDTH-1 -: DATA_WIDTH], table_expected[index_target]);
                        end else begin 
                            $display("%0t table_read_compare: Data %0d is read from index %0d", $realtime, data_rd[(j+1)*DATA_WIDTH-1 -: DATA_WIDTH], index_target);
                        end
                    end  
                end 
                setup_done = 1;
            end
        end
        //final index_queue request 
        @(posedge(clk)) begin
            #1;
            for (int j=0; j<OUTPUT_RATE; j=j+1) begin
                index_target = index_queue.pop_front();
                index_rd[(j+1)*INDEX_WIDTH-1 -: INDEX_WIDTH] = index_target; 
                if(setup_done) begin
                    index_target = index_temp.pop_front();
                    if(data_rd[(j+1)*DATA_WIDTH-1 -: DATA_WIDTH] !== table_expected[index_target]) begin
                        err_cnt = err_cnt + 1;
                        $error("%0t table_read_compare: data read at index %0d is incorrect, ACT:%0d , EXP:%0d ", $realtime, index_target, data_rd[(j+1)*DATA_WIDTH-1 -: DATA_WIDTH], table_expected[index_target]);
                    end else begin 
                        $display("%0t table_read_compare: Data %0d is read from index %0d", $realtime, data_rd[(j+1)*DATA_WIDTH-1 -: DATA_WIDTH], index_target);
                    end
                end  
            end 
            setup_done = 1;
            rd_en <= 0;
        end
    endtask

    initial begin
        string vcdfile;
        int vcdlevel;
        int seed;
        int temp;

        rst = 1'b1;
        if ($value$plusargs("VCDFILE=%s",vcdfile))
            $dumpfile(vcdfile);
        if ($value$plusargs("VCDLEVEL=%d",vcdlevel))
            $dumpvars(vcdlevel,tb);
        if ($value$plusargs("SEED=%d",seed)) begin
            temp = $urandom(seed);
            $display("Seed = %d",seed);
        end
        // rst = 1;
        // #100 
        // rst = 0;
        repeat(TB_TEST_WEIGHT) begin
            rst = 1;
            #100 
            for (int i=0; i<TABLE_SIZE; i=i+1) begin
              table_expected[i] = {(DATA_WIDTH-1){1'b0}};
            end
            rst = 0;
            $display("\n%0t TABLE RANDOM WRITE SEQ",$realtime);
            table_write_random(20);
            #1000;
            $display("\n%0t TABLE READ SEQ",$realtime);
            table_read_compare();
            #1000;
        end
    
        #1000;
        if (err_cnt > 0) begin
            $display("\n%0t TEST FAILED",$realtime);
            $display("Error count = %d\n", err_cnt);
        end else
            $display("\n%0t TEST PASSED\n", $realtime);
        $finish;
    end

    initial begin
        #((TB_SIM_TIMEOUT)* 1ms);
        $display("\n%0t TEST FAILED", $realtime);
        $display("SIM TIMEOUT!\n");
        $finish;
    end

endmodule

