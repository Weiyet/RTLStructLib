`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 04/18/2024 08:27:34 PM
// Module Name: tb
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: 1. fifo_write_burst_rand 
//              2. fifo_read_burst
//              3. fifo_burst_rand
//              4. fifo_read_write_rand_simul
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb(
);
parameter DEPTH = 12; // DUT parameter
parameter DATA_WIDTH = 8; // DUT paramter
parameter ASYNC = 1; // DUT parameter
parameter TEST_WEIGHT = 1; // TB multiplier for stimulus injected
parameter WR_CLK_PERIOD = 20; // TB wr_clk generator
parameter RD_CLK_PERIOD = 32; // TB rd_clk generator
parameter SIM_TIMEOUT = 100000; // TB simulation time out
parameter BURST_LENGHT = DEPTH;
localparam MAX_DATA = 2**DATA_WIDTH - 1;
integer fifo_expected [$];
integer i; 
integer err_cnt = 0;
reg rd_clk = 0; 
reg wr_clk = 0;
reg rst = 1;
reg [DATA_WIDTH-1:0] data_wr = 0;
reg wr_en = 0;
reg rd_en = 0;
wire [DATA_WIDTH-1:0] data_rd;
wire fifo_empty;
wire fifo_full;

fifo #(
.DEPTH(DEPTH), 
.DATA_WIDTH(DATA_WIDTH), 
.ASYNC(ASYNC)) DUT (
    /*input wire*/ .rd_clk(rd_clk),
    /*input wire*/ .wr_clk(wr_clk),
    /*input wire*/ .rst(rst),
    /*input wire [DATA_WIDTH-1:0]*/ .data_wr(data_wr),
    /*input wire*/ .wr_en(wr_en),
    /*output wire*/ .fifo_full(fifo_full),
    /*output wire [DATA_WIDTH-1:0]*/ .data_rd(data_rd),
    /*input wire*/ .rd_en(rd_en),
    /*output wire*/ .fifo_empty(fifo_empty));

always #(RD_CLK_PERIOD>>1) rd_clk = ~rd_clk;
always #(WR_CLK_PERIOD>>1) wr_clk = ~wr_clk;


integer data_wr_rand = 0;

task fifo_write_burst_rand (input integer count);
    for (i=0; i<count; i=i+1) begin
        @(posedge(wr_clk)) begin
            if(i < DEPTH & fifo_full) begin
                $display("%0t ERROR: FIFO is not full but fifo_full flag is asserted", $realtime);
                err_cnt = err_cnt + 1;
            end
            wr_en <= 1;
            data_wr_rand = $urandom_range(0,MAX_DATA);
            data_wr <= data_wr_rand;
            if ($size(fifo_expected) < DEPTH) begin 
                fifo_expected.push_back(data_wr_rand);
                $display("%0t Data written = %0d, FIFO entry = %0d", $realtime, data_wr_rand, $size(fifo_expected));
            end else begin // check FIFO FULL flag
                #1;
                if(fifo_full) 
                    $display("%0t FIFO is full, fifo_full flag is asserted correctly", $realtime);
                else begin
                    $display("%0t ERROR: FIFO is full but fifo_full flag is not asserted", $realtime);
                    err_cnt = err_cnt + 1;
                end
            end
        end
    end
    @(posedge(wr_clk))
    wr_en <= 0;
endtask

integer data_rd_act = 0;
integer data_rd_exp = 0; 

task fifo_read_burst (input integer count);
    @(posedge(rd_clk))
    rd_en <= 1;
    for (i=0; i<count; i=i+1)  begin
        @(posedge(rd_clk))begin
            if ($size(fifo_expected) > 0) begin  
                if(fifo_empty) begin
                    $display("%0t ERROR: FIFO is not empty but fifo_empty flag is asserted", $realtime);
                    err_cnt = err_cnt + 1;
                end
                data_rd_exp = fifo_expected.pop_front();
                data_rd_act <= data_rd; 
                #1; //to make sure data_rd_act capture data_rd signal.
                if(data_rd_exp == data_rd_act) 
                    $display("%0t Data read = %d, FIFO entry = %d", data_rd_act, $realtime, $size(fifo_expected));
                else begin
                    $display("%0t EERROR: Data read mismatch, ACT = %d, EXP =%d, FIFO entry = %d", $realtime, data_rd_act, data_rd_exp, $size(fifo_expected));
                    err_cnt = err_cnt + 1;
                end        
            end else begin // check FIFO EMPTY flag
                #1;
                if(fifo_empty) 
                    $display("%0t FIFO is empty, fifo_empty flag is asserted correctly", $realtime);
                else begin
                    $display("%0t ERROR: FIFO is empty but fifo_empty flag is not asserted", $realtime);
                    err_cnt = err_cnt + 1;
                end
            end
        end
    end
//    @(posedge(rd_clk))
    rd_en <= 0;
endtask

integer op_count = 0;
integer j = 0;
bit op_sel = 0;

task fifo_burst_rand(int count);
    j = count;
    while(j >= 0) begin
      op_sel = $random(); 
      op_count = $urandom_range(1,j); // to have continuous request
      j = j - op_count;
      case(op_sel) 
        1: begin // read
            fifo_read_burst(op_count);
            #RD_CLK_PERIOD;
            #(3*WR_CLK_PERIOD); // It might take extra cycle for rd_pointer synchronization to deassert fifo_full, used for write operation
        end
        0: begin // write 
            fifo_write_burst_rand(op_count);
            #WR_CLK_PERIOD;
            #(3*RD_CLK_PERIOD); // It might take extra cycle for wr_pointer synchronization to deassert fifo_empty, used for read operation
        end
      endcase 
    end
endtask

integer fifo_wr_stream [$];
integer fifo_rd_stream [$];


task fifo_read_write_rand_simul();
    fifo_read_burst($size(fifo_expected)); // to make sure FIFO is empty   
    fifo_wr_stream = {};
    fifo_rd_stream = {};
    for(i = 0; i < DEPTH; i = i+1) begin
        data_wr_rand = $urandom_range(0, MAX_DATA+1);
        fifo_wr_stream.push_back(data_wr_rand);
    end
    fork 
        begin
           for (i=0; i<BURST_LENGHT; i=i+1) begin  
                @(posedge(wr_clk))
                wr_en <= 1;
                data_wr <= fifo_wr_stream[i];
                fifo_expected.push_back(fifo_wr_stream[i]);
                $display("%0t Data written = %d, FIFO entry = %d", $realtime, fifo_wr_stream[i], $size(fifo_expected));
           end
           @(posedge(wr_clk))
           wr_en = 0;
        end
        begin
           @(posedge(rd_clk))
           rd_en = 1;
           while($size(fifo_wr_stream) != DEPTH)begin
              @(posedge(rd_clk))
              if(!fifo_empty) begin
                 data_rd_act <= data_rd;
                 fifo_rd_stream.push_back(data_rd_act);
                 data_rd_exp = fifo_expected.pop_front();
                 $display("%0t Data read = %d, FIFO entry = %d", $realtime, data_rd_act, $size(fifo_expected));
              end 
           end
//           @(posedge(rd_clk))
           rd_en = 0;        
        end
    join
    for(i=0;i<DEPTH;i=i+1) begin
        if (fifo_wr_stream[i] != fifo_rd_stream[i]) begin
            $display("%0t ERROR data_rd %d does not match data_wr %d", $realtime, fifo_rd_stream[i], fifo_wr_stream[i]);
            err_cnt = err_cnt + 1;
        end
    end
endtask

initial begin
    string vcdfile;
    int vcdlevel;

    rst = 1'b1;
    if ($value$plusargs("VCDFILE=%s",vcdfile))
        $dumpfile(vcdfile);
    if ($value$plusargs("VCDLEVEL=%d",vcdlevel))
        $dumpvars(vcdlevel);
    rst = 1;
    #100 
    rst = 0;
    repeat(TEST_WEIGHT) begin
        $display("\n%0t FIFO WRITE BURST SEQ",$realtime);
        fifo_write_burst_rand(DEPTH+3);
        #1000;
        $display("\n%0t FIFO READ BURST SEQ",$realtime);
        fifo_read_burst(DEPTH+3);
        #1000;
    end
    $display("\n%0t FIFO RANDOM READ WRITE SEQ",$realtime);
    fifo_burst_rand(TEST_WEIGHT*DEPTH);
    #1000;
    repeat(TEST_WEIGHT) begin
        $display("\n%0t FIFO SIMULTANEOUS RANDOM READ WRITE SEQ",$realtime);
        fifo_read_write_rand_simul();
    end
    #1000;
    if (err_cnt > 0) begin
        $display("\n%0t TEST FAILED",$realtime);
        $display("Error count = %d\n", err_cnt);
    end else
        $display("\n%0t TEST PASSED\n", $realtime);
    $stop;
end

initial begin
    #(SIM_TIMEOUT);
    $display("\n%0t TEST FAILED", $realtime);
    $display("SIM TIMEOUT!\n");
    $stop;
end

endmodule
