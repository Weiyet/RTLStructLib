`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 09/22/2024 01:42:52 PM
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Last Update: 15/06/2025 01:29 PM
// Last Updated By: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Module Name: tb
// Description: Supported Operation 
//             0. Read(index_in) -> data_out 
//             1. Insert(index_in, data_in) 
//             2. Find_all_index(index_in) -> data_out (array of indexes)
//             3. Find_1st_index(index_in) -> data_out (index of first occurrence)
//             4. Sum() -> data_out (sum of all elements)
//             5. Sort_Asc()
//             6. Sort_Des() 
//             7. Delete(index_in)
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb(
    );
    // DUT parameter
    localparam DUT_DATA_WIDTH = 8;
    localparam DUT_LENGTH = 8; // Max number of nodes in the list
    localparam DUT_SUM_METHOD = 0; // 0: parallel (combo) sum, 1: sequentia sum, 2: adder tree. //ICARUS does not support string overriden to parameter in CLI.

    // TB parameter
    localparam TB_CLK_PERIOD = 25;
    localparam TB_TEST_WEIGHT = 1;
    localparam SIM_TIMEOUT = 500000;

localparam LENGTH_WIDTH =  $clog2(DUT_LENGTH);
localparam DATA_OUT_WIDTH = LENGTH_WIDTH+DUT_DATA_WIDTH-1;

localparam OP_Read = 3'b000; 
localparam OP_Insert = 3'b001;
localparam OP_Find_all_index = 3'b010;
localparam OP_Find_1st_index = 3'b011;
localparam OP_Sum = 3'b100;
localparam OP_Sort_Asc = 3'b101;
localparam OP_Sort_Des = 3'b110;
localparam OP_Delete = 3'b111;

integer err_cnt = 0;

// input 
reg clk = 0;
reg rst = 0;
reg [2:0] op_sel = 0; 
reg op_en = 0; // Enable operation
reg [DUT_DATA_WIDTH-1:0] data_in = 0;
reg [LENGTH_WIDTH-1:0] index_in = 0; // Index for Insert_At_Index and Delete_At_Index
// output
wire [DUT_DATA_WIDTH+LENGTH_WIDTH-1:0] data_out; // Data out for Read and Insert_At_Index
wire op_done; // Operation done flag
wire op_in_progress; // Operation in progress flag
wire op_error; // Operation error flag
wire [$clog2(DUT_LENGTH+1)-1:0] len; // Current length of the list



`ifdef XILINX_GLS
    // for xilinx gate sim
    glbl glbl();
`endif

   list #(
      .DATA_WIDTH(DUT_DATA_WIDTH),
      .LENGTH(DUT_LENGTH),
      .SUM_METHOD(DUT_SUM_METHOD)
   ) DUT (
      /*input  wire                              */.clk(clk),
      /*input  wire                              */.rst(rst),
      /*input  wire [1:0]                        */.op_sel(op_sel),
      /*input  wire                              */.op_en(op_en),
      /*input  wire [DATA_WIDTH-1:0]             */.data_in(data_in),
      /*input  wire [LENGTH_WIDTH-1:0]           */.index_in(index_in),	
      /*output reg  [LENGTH_WIDTH+DATA_WIDTH-1:0]*/.data_out(data_out),  
      /*output reg                               */.op_done(op_done),
      /*output reg                               */.op_in_progress(op_in_progress),
      /*output reg                               */.op_error(op_error),
      /*output wire                              */.len(len)
   );
    
always #(TB_CLK_PERIOD/2) clk = ~clk; 

integer list_exp[$]; // expected list contents
integer temp[$]; // temporary storage for find_index results

task list_print_contents();
   for (integer i = 0; i < list_exp.size(); i = i + 1) begin
      $write("%0d ", list_exp[i]); // $write does not add newline
   end
   $write("\n");
endtask 

task find_index (input integer value); // input integer list[$], ref integer addr[$]); icarus does not support "ref" (pass by reference).
begin
   temp = {};
   for (integer i = 0; i < list_exp.size(); i = i + 1) begin
      if(value == list_exp[i]) begin
         temp.push_back(i);
         //$display("%0t Value %0d is found at Index %0d", $realtime, value, i);
      end
   end
end
endtask

task read (input integer index);
begin
   $display("\n%0t OP_Read at index %0d", $realtime,index); 
   @(posedge (clk));
   #1 
   op_sel = OP_Read;  
   op_en = 1;
   index_in = index;
   @(posedge (clk));
   #1
   wait (op_done); 
   if(index >= list_exp.size()) begin
      if(op_error) begin
         $display("%0t Data read out of bound, fault flag is asserted correctly",$realtime);
      end else begin
         $error("%0t Data read out of bound, fault flag is not asserted",$realtime);
         err_cnt = err_cnt + 1;
      end
   end else begin
      if(op_error) begin
         $error("%0t fault flag is asserted incorrectly",$realtime);
         err_cnt = err_cnt + 1;
      end
      if(data_out == list_exp[index]) begin
         $display("%0t Data read: %0d",$realtime,data_out);
      end else begin
         $error("%0t Data read: %0d, Data Exp: %0d", $realtime, data_out, list_exp[index]);
         err_cnt = err_cnt + 1; 
      end
   end
   @(posedge (clk));
   #1
   op_en = 0;
end
endtask

integer count = 0;

task read_n_burst(input integer n);
begin
   $display("\n%0t OP_Read burst %0d time", $realtime,n); 
   count = 0;
   @(posedge (clk));
   #1 
   op_sel = OP_Read;  
   op_en = 1;
   index_in = count;
   while (count < n) begin
      @(posedge (clk));
      #1
      wait (op_done); 
      if(index_in >= list_exp.size()) begin
         if(op_error) begin
            $display("%0t Data read out of bound, fault flag is asserted correctly",$realtime);
         end else begin
            $error("%0t Data read out of bound, fault flag is not asserted",$realtime);
            err_cnt = err_cnt + 1;
         end
      end else begin
         if(op_error) begin
            $error("%0t fault flag is asserted incorrectly",$realtime);
            err_cnt = err_cnt + 1;
         end
         if(data_out == list_exp[index_in]) begin
            $display("%0t Data read: %0d",$realtime,data_out);
         end else begin
            $error("%0t Data read: %0d, Data Exp: %0d", $realtime, data_out, list_exp[index_in]);
            err_cnt = err_cnt + 1; 
         end
      end
      count = count + 1;
      index_in = count;
   end
   @(posedge (clk));
   #1
   op_en = 0;
end
endtask

task insert(input integer index, input integer value);
begin
   $display("\n%0t OP_Insert at index %0d, value %0d", $realtime,index,value); 
   @(posedge (clk));
   #1 
   op_sel = OP_Insert;  
   op_en = 1;
   index_in = index;
   data_in = value;
   @(posedge (clk));
   #1
   wait (op_done); 
   if(list_exp.size() >= DUT_LENGTH) begin
      if(op_error) begin
         $display("%0t Data insert out of bound, fault flag is asserted correctly",$realtime);
      end else begin
         $error("%0t Data insert out of bound, fault flag is not asserted",$realtime);
         err_cnt = err_cnt + 1;
      end
   end else begin
      if(op_error) begin
         $error("%0t fault flag is asserted incorrectly",$realtime);
         err_cnt = err_cnt + 1;
      end
      if(index > list_exp.size()) begin
         list_exp.push_back(value); // Insert at the end if index is out of bound
      end else begin
         list_exp.insert(index, value);
      end
   end
   if(len!= list_exp.size()) begin
      $error("%0t Length mismatch: Expected %0d, Got %0d", $realtime, list_exp.size(), len);
      err_cnt = err_cnt + 1;
   end 
   @(posedge (clk));
   #1
   op_en = 0;
   list_print_contents();
end
endtask

task delete(input integer index);
begin
    $display("\n%0t OP_Delete at index %0d", $realtime,index); 
    @(posedge (clk));
    #1 
    op_sel = OP_Delete;  
    op_en = 1;
    index_in = index;
    @(posedge (clk));
    #1
    wait (op_done); 
    if(index >= list_exp.size()) begin
       if(op_error) begin
          $display("%0t Data delete out of bound, fault flag is asserted correctly",$realtime);
       end else begin
          $error("%0t Data delete out of bound, fault flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end
    end else begin
       if(op_error) begin
          $error("%0t fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end
       list_exp.delete(index);
    end
    if(len!= list_exp.size()) begin
       $error("%0t Length mismatch: Expected %0d, Got %0d", $realtime, list_exp.size(), len);
       err_cnt = err_cnt + 1;
    end 
    @(posedge (clk));
    #1
    op_en = 0;
    list_print_contents();
end
endtask

task sort_acending();
begin
   int temp;
   $display("\n%0t OP_Sort_Asc Request", $realtime); 
   @(posedge (clk));
   #1 
   op_sel = OP_Sort_Asc;  
   op_en = 1;
   @(posedge (clk));
   #1
   wait (op_done); 
   for (integer i = 0; i < list_exp.size() - 1; i = i + 1) begin
      for (integer j = i + 1; j < list_exp.size(); j = j + 1) begin
         if(list_exp[i] > list_exp[j]) begin
            temp = list_exp[i];
            list_exp[i] = list_exp[j];
            list_exp[j] = temp;
         end
      end
   $display("%0t OP_Sort_Asc Complete", $realtime); 
   end
   @(posedge (clk));
   #1
   op_en = 0;
   list_print_contents();
end
endtask

task sort_desending();
begin
   int temp;
   $display("\n%0t OP_Sort_Des Request", $realtime); 
   @(posedge (clk));
   #1 
   op_sel = OP_Sort_Des;  
   op_en = 1;
   @(posedge (clk));
   #1
   wait (op_done); 
   for (integer i = 0; i < list_exp.size() - 1; i = i + 1) begin
      for (integer j = i + 1; j < list_exp.size(); j = j + 1) begin
         if(list_exp[i] < list_exp[j]) begin
            temp = list_exp[i];
            list_exp[i] = list_exp[j];
            list_exp[j] = temp;
         end
      end
   end
   $display("%0t OP_Sort_Des Complete", $realtime); 
   @(posedge (clk));
   #1
   op_en = 0;
   list_print_contents();
end
endtask

integer sum_result = 0;

task sum();
begin
   $display("\n%0t OP_Sum Request", $realtime);
   @(posedge (clk));
   #1
   op_sel = OP_Sum;
   op_en = 1;
   @(posedge (clk));
   #1
   wait (op_done);
   for (integer i = 0; i < list_exp.size(); i = i + 1) begin
      sum_result += list_exp[i];
   end
   if(data_out == sum_result) begin
      $display("%0t Sum: %0d",$realtime,data_out);
   end else begin
      $error("%0t Sum: %0d, Expected: %0d", $realtime, data_out, sum_result);
      err_cnt = err_cnt + 1;
   end
   @(posedge (clk));
   #1
   op_en = 0;
end
endtask

task find_1st_index(input integer value);
begin
   $display("\n%0t OP_Find_1st_index for value %0d", $realtime, value);
   @(posedge (clk));
   #1
   op_sel = OP_Find_1st_index;
   op_en = 1;
   data_in = value;
   @(posedge (clk));
   #1
   wait (op_done);
   find_index(value); // -> temp
   if(temp.size() > 0) begin
      if(data_out == temp[0]) begin
         $display("%0t First index of value %0d is %0d", $realtime, value, data_out);
      end else begin
         $error("%0t First index of value %0d is %0d, Expected: %0d", $realtime, value, data_out, temp[0]);
         err_cnt = err_cnt + 1;
      end
   end else begin
      if(op_error) begin
         $display("%0t Value %0d not found, fault flag is asserted correctly",$realtime,value);
      end else begin
         $error("%0t Value %0d not found, fault flag is not asserted",$realtime,value);
         err_cnt = err_cnt + 1;
      end
   end
   @(posedge (clk));
   #1
   op_en = 0;
end
endtask

integer data_out_cnt;

task find_all_index(input integer value);
begin
   $display("\n%0t OP_Find_all_index for value %0d", $realtime, value);
   @(posedge (clk));
   #1
   op_sel = OP_Find_all_index;
   op_en = 1;
   data_in = value;
   find_index(value); // -> temp
   data_out_cnt = 0;
   @(posedge (clk));
   #1;
   if (temp.size() == 0) begin
      wait (op_done);
      if(op_error) begin
         $display("%0t Value %0d not found, fault flag is asserted correctly",$realtime,value);
      end else begin
         $error("%0t Value %0d not found, fault flag is not asserted",$realtime,value);
         err_cnt = err_cnt + 1;
      end
   end else begin 
      while (data_out_cnt < temp.size()) begin
         if(op_done) begin
            if(temp[data_out_cnt] == data_out) begin
               $display("%0t Value %0d is found at index %0d", $realtime, value, data_out);
            end else begin
               $error("%0t Value %0d should be found at index %0d but index %0d is reported by DUT", $realtime, value, temp[data_out_cnt], data_out);
               err_cnt = err_cnt + 1;
            end
            data_out_cnt = data_out_cnt + 1;
         end
         if((data_out_cnt < (temp.size()-1)) & !op_in_progress) begin
            $display("%0t OP_Find_all_index All index is not found yet, but op_in_progress is deasserted incorrectly", $realtime);
            data_out_cnt = temp.size(); // Icarus does not support "break" statement, use assignment to force exit loop
         end else if((data_out_cnt == (temp.size()-1)) & !op_in_progress) begin
            $display("%0t OP_Find_all_index All index is found, but op_in_progress is asserted incorrectly", $realtime);
         end
         if(op_error) begin
            $error("%0t fault flag is asserted incorrectly",$realtime);
            err_cnt = err_cnt + 1;
         end
         @(posedge (clk));
         #1;
      end
   end
   op_en = 0;
end
endtask

task direct_op_test();
begin
   $display("Starting direct operation test");

   // Insert operation
   insert(0,$urandom_range(0,2**DUT_DATA_WIDTH-1)); 
   insert(1,$urandom_range(0,2**DUT_DATA_WIDTH-1));
   insert(2,$urandom_range(0,2**DUT_DATA_WIDTH-1)); 
   //insert(0,1);
   //insert(1,2);
   //insert(2,3);
   insert(3,list_exp[2]);
   insert(2,list_exp[0]);
   
   // Read operation
   read(0);
   read(1);
   read(2);
   read(3);
   read(4); 
   read(5); // Read out of bound, should assert fault flag

   delete(5); // Delete out of bound, should assert fault flag
   delete(3); 

   // sum operation
   sum();

   // Sort Ascending
   sort_acending();
   // Read after sort
   read_n_burst(4);

   // Sort Descending
   sort_desending();
   // Read after sort
   read_n_burst(4);

   // Find 1st index
   find_1st_index(list_exp[1]);

   // Find all index
   find_all_index(list_exp[2]);

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
        $display("Seed = %0d",seed);
    end
    #100;
    rst = 1'b0;
    direct_op_test();
    
    #1000;
    
    if (err_cnt > 0) begin
        $display("\n%0t TEST FAILED",$realtime);
        $display("Error count = %0d\n", err_cnt);
    end else
        $display("\n%0t TEST PASSED\n", $realtime);
    $finish;
end

initial begin
    #(SIM_TIMEOUT)
    $display("\n%0t TEST FAILED", $realtime);
    $display("SIM TIMEOUT!\n");
    $finish;
end

endmodule
