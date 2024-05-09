`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 05/05/2024 05:05:34 PM
// Last Update Date: 05/05/2024 05:05:34 PM
// Module Name: tb
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: 1. lifo_random_op_test
//                  - Read/Write/Read_write_simultaneous 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb(
);
parameter DEPTH = 12; // DUT parameter
parameter DATA_WIDTH = 8; // DUT paramter
parameter CLK_PERIOD = 20; // TB clk generator
parameter SIM_TIMEOUT = 100000; // TB simulation time out
parameter TEST_WEIGHT = 1; //TB Test weight

integer lifo_expected [$];
integer i; 
integer op_sel,op_count;
integer err_cnt = 0;
reg clk = 0; 

reg rst = 1;
reg [DATA_WIDTH-1:0] data_wr = 0;
reg wr_en = 0;
reg rd_en = 0;
wire [DATA_WIDTH-1:0] data_rd;
wire lifo_empty;
wire lifo_full;

lifo #(
.DEPTH(DEPTH), 
.DATA_WIDTH(DATA_WIDTH)) DUT (
    /*input wire*/ .clk(clk),
    /*input wire*/ .rst(rst),
    /*input wire [DATA_WIDTH-1:0]*/ .data_wr(data_wr),
    /*input wire*/ .wr_en(wr_en),
    /*output reg*/ .lifo_full(lifo_full),
    /*output reg [DATA_WIDTH-1:0]*/ .data_rd(data_rd),
    /*input wire*/ .rd_en(rd_en),
    /*output wire*/ .lifo_empty(lifo_empty));

always #(CLK_PERIOD>>1) clk = ~clk;

integer exp_data_wr = 0;

task lifo_write(input integer wr_data_array[$]);
    while($size(wr_data_array) != 0) begin
        exp_data_wr = wr_data_array.pop_front();
        @(posedge(clk))
        wr_en <= 1;
        data_wr <= exp_data_wr;
        #1
        if($size(lifo_expected)<DEPTH) begin
            if(!lifo_full) begin
                lifo_expected.push_back(exp_data_wr);
                $display("%0t Data written = %d, entry = %d",$realtime,exp_data_wr,$size(lifo_expected));
            end
            else begin
                $error("%0t LIFO is not full but lifo_full flag is asserted incorrectly",$realtime);
                err_cnt = err_cnt + 1;
            end 
        end else begin
            if(lifo_full) begin
                $display("%0t LIFO is full, lifo_full flag is asserted correctly",$realtime);
            end
            else begin
                $error("%0t LIFO is full but lifo_full flag is not asserted",$realtime);
                err_cnt = err_cnt + 1;
            end 
        end
    end
    @(posedge(clk))
    wr_en <= 0;
endtask

integer j;
integer act_data_rd = 0;
integer exp_data_rd = 0;

task lifo_read(input integer count);
    @(posedge(clk))
    rd_en <= 1;
    for (j = 0; j<count; j=j+1)begin
       @(posedge(clk))
       if($size(lifo_expected)>0) begin
            if(lifo_empty) begin
                $error("%0t LIFO is not empty but lifo_empty flag is asserted incorrectly",$realtime);
            end
            #1
            act_data_rd = data_rd;
            exp_data_rd = lifo_expected.pop_back();
            if(act_data_rd == exp_data_rd) begin
               $display("%0t Data read = %d, FIFO entry = %d", $realtime, act_data_rd, $size(lifo_expected));
            end 
            else begin
               $error("%0t Data read mismatch, ACT = %d, EXP =%d, FIFO entry = %d", $realtime, act_data_rd, exp_data_rd, $size(lifo_expected));
               err_cnt = err_cnt + 1;
            end
       end else begin
            if(!lifo_empty) begin
                $error("%0t LIFO is empty but lifo_empty flag is not asserted",$realtime);
                err_cnt = err_cnt + 1;
            end 
            else begin
                $display("%0t LIFO is empty, lifo_empty flag is asserted correctly",$realtime);
            end 
       end 
    end
    rd_en = 0;
endtask

task lifo_simul_read_write(input integer wr_data_array[$]);
    exp_data_wr = wr_data_array.pop_front();
    @(posedge(clk))
    rd_en <= 1;
    wr_en <= 1;
    data_wr <= exp_data_wr;    
    
    while($size(wr_data_array) != 0) begin
        @(posedge(clk))
        #1 
        act_data_rd = data_rd;
        if(act_data_rd == exp_data_wr) begin    
            $display("%0t Simultaneous Data read/write = %d, FIFO entry = %d", $realtime, act_data_rd, $size(lifo_expected));
        end
        else begin
            $error("%0t Simultaneous Data read/write, ACT = %d, EXP = %d, FIFO entry = %d", $realtime, act_data_rd, exp_data_wr, $size(lifo_expected));
        end
        #1
        exp_data_wr = wr_data_array.pop_front();
        data_wr <= exp_data_wr;
    end
    @(posedge(clk))
    wr_en <= 0;
    rd_en <= 0;
    #1
    act_data_rd = data_rd;
    if(act_data_rd == exp_data_wr) begin    
        $display("%0t Simultaneous Data read/write = %d, FIFO entry = %d", $realtime, act_data_rd, $size(lifo_expected));
    end
    else begin
        $error("%0t Simultaneous Data read/write, ACT = %d, EXP = %d, FIFO entry = %d", $realtime, act_data_rd, exp_data_wr, $size(lifo_expected));
    end
endtask

integer wr_data_array[$];
integer k;

task lifo_random_op_test(input integer count);
    i = count;
    while (i > 0) begin
        op_sel = $urandom_range(0,2);
        op_count = $urandom_range(1,i);
        i = i - op_count;
        case(op_sel)
            0: begin // read
                 $display("%0t LIFO Read %d times", $realtime, op_count);
                lifo_read(op_count);
            end
            1: begin // write
                 $display("%0t LIFO Write %d times", $realtime, op_count);
                for(k=0 ; k < op_count; k = k+1) begin
                    wr_data_array.push_back($urandom_range(0,2**DATA_WIDTH-1));
                end
                lifo_write(wr_data_array);
            end
            2: begin // simultaneous read write
                $display("%0t LIFO Simul Read Write %d times", $realtime, op_count);
                for(k=0 ; k < op_count; k = k+1) begin
                    wr_data_array.push_back($urandom_range(0,2**DATA_WIDTH-1));
                end
                lifo_simul_read_write(wr_data_array);
            end
        endcase
    end
endtask

initial begin
    string vcdfile;
    int vcdlevel;
    int seed;
    int temp;
    if ($value$plusargs("VCDFILE=%s",vcdfile))
        $dumpfile(vcdfile);
    if ($value$plusargs("VCDLEVEL=%d",vcdlevel))
        $dumpvars(vcdlevel, tb);
        $display("Seed number: %d",vcdlevel);
    if ($value$plusargs("SEED=%d",seed)) begin
        $display("Seed number: %d",seed);
        temp = $urandom(seed);
    end
    
    repeat(TEST_WEIGHT) begin
        rst = 1;
        #100 
        rst = 0;
        #100
        lifo_expected = {};
        lifo_random_op_test(DEPTH);
        #1000;
    end
    if (err_cnt > 0) begin
        $display("\n%0t TEST FAILED",$realtime);
        $display("Error count = %d\n", err_cnt);
    end else
        $display("\n%0t TEST PASSED\n", $realtime);
    $finish;
end

initial begin
    #(SIM_TIMEOUT);
    $display("\n%0t TEST FAILED", $realtime);
    $display("SIM TIMEOUT!\n");
    $finish;
end

endmodule
