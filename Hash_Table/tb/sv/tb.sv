`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Create Date: 26/04/2025 03:37:34 PM
// Last Update: 03/05/2025 6:20 PM
// Module Name: tb
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb(
);
    parameter DUT_KEY_WIDTH = 32;
    parameter DUT_VALUE_WIDTH = 32;
    parameter DUT_TOTAL_INDEX = 8;  // Total index of the hash table
    parameter DUT_CHAINING_SIZE = 4; // Number of chains for SINGLE_CYCLE_CHAINING and MULTI_STAGE_CHAINING only
    parameter DUT_COLLISION_METHOD = "MULTI_STAGE_CHAINING";  // "MULTI_STAGE_CHAINING", "LINEAR_PROBING" 
    parameter DUT_HASH_ALGORITHM = "MODULUS";  // "MODULUS", "SHA1", "FNV1A"
    parameter TB_CLK_PERIOD = 100;
    parameter TB_TEST_WEIGHT = 1; 
    parameter TB_SIM_TIMEOUT = 30; //ms.

    localparam MAX_VALUE = 2**(DUT_VALUE_WIDTH)-1;
    localparam INDEX_WIDTH = $clog2(DUT_TOTAL_INDEX);
    localparam CHAIN_WIDTH = $clog2(DUT_CHAINING_SIZE);

    // associative array datatype is not supported by icarus 
    // icarus does not support 2d queue.
    reg [DUT_KEY_WIDTH-1:0] expected_hash_key [0:DUT_TOTAL_INDEX-1][0:DUT_CHAINING_SIZE-1];
    reg [DUT_VALUE_WIDTH-1:0] expected_hash_value  [0:DUT_TOTAL_INDEX-1][0:DUT_CHAINING_SIZE-1];
    integer expected_hash_entry_count [0:DUT_TOTAL_INDEX-1];

    reg clk=0;
    reg rst=0;
    reg [DUT_KEY_WIDTH-1:0] key_in=0;
    reg [DUT_VALUE_WIDTH-1:0] value_in=0;
    reg [1:0] op_sel=0;
    reg op_en=0;
    wire [DUT_VALUE_WIDTH-1:0] value_out;
    wire op_done;
    wire op_error;
    wire [CHAIN_WIDTH-1:0] collision_count;
    integer index_out;
    integer error;
    integer data_rd;

    integer err_cnt = 0;

    // Hash function selector
    function integer get_hash_index;
        input integer key;
        reg [31:0] hash_value;
        begin
            if (DUT_HASH_ALGORITHM == "MODULUS")
                hash_value = key % DUT_TOTAL_INDEX;
            else // for future implentation of other hash algorithm
                hash_value = key;
                
            get_hash_index = hash_value[INDEX_WIDTH-1:0];
        end
    endfunction
    
    integer temp;
    
    task find_first_index (input integer key, output integer index_out); // icarus does not support in built method find_first_index
    begin
       index_out = -1;
       temp = get_hash_index(key);
       for (integer i = 0; i < expected_hash_entry_count[temp]; i = i + 1) begin
          if(key == expected_hash_key[temp][i]) begin
             index_out = i;
             $display("%0t find_first_index: Key %0d is found at Index %0d Chain no %0d", $realtime, key, temp, i);
          end
       end
       if (index_out == -1) begin
          $display("%0t find_first_index: Key %0d is not found", $realtime, key);
       end
    end
    endtask

    task print_hash_table;
    begin
       for (integer i = 0; i < DUT_TOTAL_INDEX; i = i + 1) begin
          $display("Hash Table Index %0d: ", i);
          for (integer j = 0; j < expected_hash_entry_count[i]; j = j + 1) begin
             $display("Key: %0d, Value: %0d", expected_hash_key[i][j], expected_hash_value[i][j]);
          end
       end
    end
    endtask

    task delete_index (input integer key, input integer index);
    begin
       temp = get_hash_index(key);
       for (integer i = index; i < expected_hash_entry_count[temp]; i = i + 1) begin
          expected_hash_key[temp][i] = expected_hash_key[temp][i+1];
          expected_hash_value[temp][i] = expected_hash_value[temp][i+1];
       end
       expected_hash_key[temp][expected_hash_entry_count[temp]-1] = 0;
       expected_hash_value[temp][expected_hash_entry_count[temp]-1] = 0;
       expected_hash_entry_count[temp] = expected_hash_entry_count[temp] - 1;
       $display("%0t delete_index: Key %0d is deleted at Index %0d Chain no %0d", $realtime, key, temp, index);
    end
    endtask
    // icarus does not support associative array datatype
    
    task reset_model;
        for (integer i = 0; i < DUT_TOTAL_INDEX; i = i + 1) begin
            expected_hash_entry_count[i] = 0;
            for (integer j = 0; j < DUT_CHAINING_SIZE; j = j + 1) begin
                expected_hash_key[i][j] = 0;
                expected_hash_value[i][j] = 0;
            end
        end
    endtask

    `ifdef XILINX_GLS
        glbl glbl (); // for Xilinx GLS
    `endif

    hash_table #(
              .KEY_WIDTH(DUT_KEY_WIDTH),
              .VALUE_WIDTH(DUT_VALUE_WIDTH),
              .TOTAL_INDEX(DUT_TOTAL_INDEX),  // Total index of the hash table
              .CHAINING_SIZE(DUT_CHAINING_SIZE), // Number of chains for SINGLE_CYCLE_CHAINING and MULTI_STAGE_CHAINING only
              .COLLISION_METHOD(DUT_COLLISION_METHOD),  // "MULTI_STAGE_CHAINING", "LINEAR_PROBING" 
              .HASH_ALGORITHM(DUT_HASH_ALGORITHM))  // "MODULUS", "SHA1", "FNV1A")) 
              DUT (
    /*input wire*/                   .clk(clk),
    /*input wire*/                   .rst(rst),
    /*input wire [KEY_WIDTH-1:0]*/   .key_in(key_in),
    /*input wire [VALUE_WIDTH-1:0]*/ .value_in(value_in),
    /*input wire [1:0]*/             .op_sel(op_sel), // 00: Insert, 01: Delete, 10: Search
    /*input wire*/                   .op_en(op_en),
    /*output reg [VALUE_WIDTH-1:0]*/ .value_out(value_out),
    /*output reg*/                   .op_done(op_done),
    /*output reg*/                   .op_error(op_error), // FULL when insert FAIL, KEY_NOT_FOUND when delete or search FAIL
    /*output reg [CHAIN_WIDTH-1:0]*/ .collision_count(collision_count));

    always #(TB_CLK_PERIOD>>1) clk = ~clk;
 
    integer target_index;
    
    task hash_table_insert(input [DUT_KEY_WIDTH-1:0] key, input [DUT_VALUE_WIDTH-1:0] value);
        @ (posedge clk) begin
            key_in <= key;
            value_in <= value;
            op_sel <= 2'b00;
            op_en <= 1;
            target_index = get_hash_index(key); 
        end
        wait(op_done)
        #1
        find_first_index(key,index_out);
        if(expected_hash_entry_count[target_index] < DUT_CHAINING_SIZE) begin
            if(index_out != -1) begin
                expected_hash_value[target_index][index_out] = value;
                $display("%0t hash_table_insert: Key %0d - Value %0d is updated to expected index %0d", $realtime, value, key, target_index);
            end else begin
                expected_hash_key[target_index][expected_hash_entry_count[target_index]] = key;
                expected_hash_value[target_index][expected_hash_entry_count[target_index]] = value;
                expected_hash_entry_count[target_index] = expected_hash_entry_count[target_index] + 1;
                $display("%0t hash_table_insert: Key %0d - Value %0d is inserted to expected index %0d", $realtime, value, key, target_index);
            end
        end else begin
            if(op_error)
               $display("%0t hash_table_insert: Key %0d - Value %0d is not inserted succesfully, chain is full, op_error is asserted correctly", $realtime, value, key);
            else begin
               $error("%0t hash_table_insert: Key %0d - Value %0d is not inserted succesfully, chain is full, op_error is not asserted expectedly", $realtime, value, key);
               err_cnt += 1;
            end
        end
        @ (posedge clk) 
        op_en <= 0;
        print_hash_table();
    endtask
    
    task hash_table_delete(input [DUT_KEY_WIDTH-1:0] key);
        @ (posedge clk) begin
            key_in <= key;
            op_sel <= 2'b01;
            op_en <= 1;
            target_index = get_hash_index(key); 
        end
        wait(op_done)
        #1
        find_first_index(key,index_out);
        if(index_out != -1) begin
            $display("%0t hash_table_delete: Key %0d at index %0d is deleted", $realtime, key, target_index);
            delete_index(key,index_out);
        end else begin
            if(op_error)
               $display("%0t hash_table_delete: Key %0d is not deleted succesfully, key is unfound, op_error is asserted correctly", $realtime, key);
            else begin
               $error("%0t hash_table_delete: Key %0d is not deleted succesfully, key is unfound, op_error is not asserted expectedly", $realtime, key);
               err_cnt += 1;
            end
        end
        @ (posedge clk) 
        op_en <= 0;
        print_hash_table();
    endtask
    
    task hash_table_search(input [DUT_KEY_WIDTH-1:0] key, output error, output [DUT_VALUE_WIDTH-1:0] data_rd);
        @ (posedge clk) begin
            key_in <= key;
            op_sel <= 2'b10;
            op_en <= 1;
            target_index = get_hash_index(key); 
        end
        wait(op_done)
        #1;
        find_first_index(key,index_out);
        if(index_out != -1) begin
            if(expected_hash_value[target_index][index_out] == value_out) 
                $display("%0t hash_table_search: Key %0d - value %0d is found", $realtime, key, value_out);
            else begin
                $error("%0t hash_table_search: Key %0d - value %0d is mismatched, expeted_value %0d", $realtime, key, value_out, expected_hash_value[target_index][index_out]);
                err_cnt += 1;
            end
        end else begin
            if(op_error)
               $display("%0t hash_table_delete: Key %0d is unfound, op_error is asserted correctly", $realtime, key);
            else begin
               $error("%0t hash_table_delete: Key %0d is unfound, op_error is not asserted expectedly", $realtime, key);
               err_cnt += 1;
            end
        end
        @ (posedge clk) 
        op_en <= 0;  
        print_hash_table();
    endtask

    task direct_basic_op_test;
        hash_table_insert(1,2);
        hash_table_search(1,error,data_rd);
        hash_table_insert(3,2);
        hash_table_insert(11,3);
        hash_table_insert(19,4);
        hash_table_insert(27,5);
        hash_table_insert(35,5);
        hash_table_insert(43,5);
        hash_table_delete(1);
        hash_table_search(19,error,data_rd);
        hash_table_search(1,error,data_rd);
        hash_table_search(3,error,data_rd);
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
        rst = 1;
        reset_model();
        #100 
        rst = 0;
        direct_basic_op_test();
        #1000;
        if (err_cnt > 0) begin
            $display("\n%0t TEST FAILED",$realtime);
            $display("Error count = %d\n", err_cnt);
        end else
            $display("\n%0t TEST PASSED\n", $realtime);
        $finish;
    end

    initial begin
        #(TB_SIM_TIMEOUT * 1ms);
        $display("\n%0t TEST FAILED", $realtime);
        $display("SIM TIMEOUT!\n");
        $finish;
    end

endmodule

