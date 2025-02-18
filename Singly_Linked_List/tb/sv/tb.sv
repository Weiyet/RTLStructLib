`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 07/11/2024 10:23:52 PM
// Last Update: 02/18/2025 09:27 PM
// Module Name: tb
// Description: Supported Operation 
//             0. Read_Addr(addr_in) -> data_out 
//             1. Insert_At_Addr(addr_in, data_in) 
//             5. Insert_At_Index(addr_in, data_in)
//             2. Delete_Value(data_in)
//             3. Delete_At_Addr(addr_in)
//             7. Delete_At_Index(addr_in) 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb(
    );
    // DUT parameter
    localparam DUT_DATA_WIDTH = 8;
    localparam DUT_MAX_NODE = 8;
    // TB parameter
    localparam TB_CLK_PERIOD = 25;
    localparam ADDR_WIDTH = $clog2(DUT_MAX_NODE+1); // Reserve {ADDR_WIDTH(1'b1)} as NULL/INVALID ADDR  
    localparam MAX_DATA = 2**DUT_DATA_WIDTH - 1;
    localparam TB_TEST_WEIGHT = 1;
    localparam SIM_TIMEOUT = 500000;

localparam ADDR_NULL = (DUT_MAX_NODE+1);

localparam OP_Read = 3'b000;
localparam OP_Insert_At_Addr = 3'b001;
localparam OP_Insert_At_Index = 3'b101;
localparam OP_Delete_Value = 3'b010;
localparam OP_Delete_At_Addr = 3'b011;
localparam OP_Delete_At_Index = 3'b111;

integer err_cnt = 0;

// input 
reg clk = 0;
reg rst = 0;
reg [DUT_DATA_WIDTH-1:0] data_in = 0; 
reg [ADDR_WIDTH-1:0] addr_in = 0; 
reg [2:0] op = 0;
reg op_start = 0;
// output
wire [DUT_DATA_WIDTH-1:0] data_out;
wire op_done;
wire [ADDR_WIDTH-1:0] next_node_addr; 
wire [ADDR_WIDTH-1:0] length;
wire [ADDR_WIDTH-1:0] head; // Addr of head
reg  [ADDR_WIDTH-1:0] pre_head;
wire [ADDR_WIDTH-1:0] tail; // Addr of tail
reg  [ADDR_WIDTH-1:0] pre_tail; // Addr of tail
wire full;
wire empty;
wire fault; 

`ifdef XILINX_GLS
    // for xilinx gate sim
    glbl glbl();
`endif
 
    singly_linked_list #(.DATA_WIDTH(DUT_DATA_WIDTH),.MAX_NODE(DUT_MAX_NODE)) DUT
    (   /*input*/  .rst(rst),
        /*input*/  .clk(clk),
        /*input [DATA_WIDTH-1:0]*/ .data_in(data_in), 
        /*input [ADDR_WIDTH-1:0]*/ .addr_in(addr_in),
        /*input [1:0]*/ .op(op), // 0: Read(addr_in); 1: Delete_Value(data_in); 2: Push_Back(data_in); 3: Push_front(data_in)
        /*input*/  .op_start(op_start), 
        /*output reg [DATA_WIDTH-1:0]*/ .data_out(data_out),
        /*output reg*/  .op_done(op_done),
        /*output wire [ADDR_WIDTH-1:0]*/ .next_node_addr(next_node_addr), // Addr of next node
        // status 
        /*output reg [ADDR_WIDTH-1:0]*/  .length(length), 
        /*output wire*/ .full(full), 
        /*output reg [ADDR_WIDTH-1:0]*/ .head(head), // Addr of head
        /*output reg [ADDR_WIDTH-1:0]*/ .tail(tail), // Addr of head
        /*output wire*/ .empty(empty),
        /*output reg*/  .fault(fault) // Invalid Errors 
    );
    
always #(TB_CLK_PERIOD/2) clk = ~clk; 

integer linked_list_exp[$];    
integer linked_list_addr[$]; // corresponding to linked_list_exp. 
integer data_wr[$];
integer i = 0;
integer next;
integer dummy[$];
integer temp[$];
integer temp2;

task list_print_contents();
   $write("%0t linked_list_exp = ", $realtime);
   for (int i = 0; i < linked_list_exp.size(); i = i + 1) begin
      $write("%0d ", linked_list_exp[i]);
   end
   $write("\n%0t linked_list_addr = ", $realtime);
   for (int i = 0; i < linked_list_addr.size(); i = i + 1) begin
      $write("%0d ", linked_list_addr[i]);
   end
   $write("\n");
endtask 

task find_first_index (input integer addr); // input integer list[$], ref integer addr[$]); icarus does not support ref.
begin
   temp = {};
   for (integer i = 0; i < linked_list_addr.size(); i = i + 1) begin
      if(addr == linked_list_addr[i]) begin
         temp.push_back(i);
         $display("%0t Addr %0d found at Index %0d", $realtime, addr, i);
      end
   end
end
endtask

task find_first_index2 (input integer addr); //avoid temp output conflict
begin
   dummy = {};
   for (integer i = 0; i < linked_list_addr.size(); i = i + 1) begin
      if(addr == linked_list_addr[i]) begin
         dummy.push_back(i);
         $display("%0t Addr %0d found at Index %0d", $realtime, addr, i);
      end
   end
end
endtask

task find_next_addr (output integer next_addr);
begin
   next_addr = 0;
   for (int i = 0; i < (linked_list_addr.size()+1); i = i + 1) begin
      dummy = {};
      //dummy = (linked_list_addr.find_first_index(x) with ( x == i )); // icarus does not support built in find_first_index method, so used workaround below. 
      find_first_index2(i);
      if(dummy.size() == 0) begin
        next_addr = i;
        //break;  //icarus does not support break statement, so used workaround below. 
        i = linked_list_addr.size()+1; 
      end
   end
   $display("%0t Next Addr = %0d", $realtime, next_addr);
end
endtask

task read_n(input integer count); 
begin
    $display("%0t OP_Read %0d times", $realtime,count); 
    i = 0;
    @(posedge (clk));
    #1 
    op = OP_Read;  
    op_start = 1;
    addr_in = head;
    i = i + 1;
    while (i<=count) begin  
        @(posedge (clk));
        #1 
        if(op_done) begin
            if( (i-1) >= linked_list_exp.size()) begin
               if(fault) begin
                  $display("%0t Data read out of bound, fault flag is asserted correctly",$realtime);
               end else begin
                  $error("%0t Data read out of bound, fault flag is not asserted",$realtime);
                  err_cnt = err_cnt + 1;
               end
            end else if(data_out == linked_list_exp[i-1]) begin
               $display("%0t Data read: %0d",$realtime,data_out);
            end else begin
               $error("%0t Data read: %0d, Data Exp: %0d", $realtime, data_out, linked_list_exp[i-1]);
               err_cnt = err_cnt + 1; 
            end
            if(i == count) begin
               op_start = 0;
            end else if ( (i-1) < linked_list_exp.size()-2) begin
               if(next_node_addr != linked_list_addr[i]) begin
                  $error("%0t Next Addr: %0d, Addr Exp: %0d", $realtime, next_node_addr, linked_list_addr[i]);
                  err_cnt = err_cnt + 1; 
               end
            end else if ( (i-1) == linked_list_exp.size()-1) begin
               if(next_node_addr != ADDR_NULL) begin
                  $error("%0t Next Addr: %0d, Addr Exp: %0d", $realtime, next_node_addr, ADDR_NULL);
                  err_cnt = err_cnt + 1; 
               end
            end
            addr_in = next_node_addr;
            i = i + 1;
        end
    end
    // icarus does not support %p concanation, so used workaround below.
    list_print_contents();
    //$display("%0t Complete OP_Read %0d times, linked_list_exp = %p", $realtime,count,linked_list_exp[0:(linked_list_exp.size()-1)]); 
    //$display("%0t Complete OP_Read %0d times, linked_list_addr = %p\n", $realtime,count,linked_list_addr[0:(linked_list_addr.size()-1)]); 
end
endtask  

bit found = 0;

task delete_value(input integer value); 
begin
    $display("%0t OP_Delete_Value %0d value", $realtime,value);    
    i = 0; 
    found = 0;
    @(posedge (clk));
    #1 
    op = OP_Delete_Value;  
    data_in = value;
    op_start = 1;
    wait (op_done)
    #1 
    for (int j = 0; j < linked_list_exp.size(); j=j+1) begin
        if(value == linked_list_exp[j]) begin
           $display("%0t Data %0d at Index %0d is Deleted_by_Value", $realtime, linked_list_exp[j],j);
           linked_list_exp.delete(j);  
           linked_list_addr.delete(j); 
           found = 1;      
           //break;
           j = linked_list_exp.size() + 1; 
        end
    end
    if (!found) begin
       if(fault) begin
          $display("%0t Data delete out of bound, fault flag is asserted correctly",$realtime);
       end else begin
          $error("%0t Data delete out of bound, fault flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end
    end else begin
       if(fault) begin
          $error("%0t fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end
    end
    op_start = 0;
    // icarus does not support %p concanation, so used workaround below.
    list_print_contents();
    //$display("%0t Complete OP_Delete_Value %0d value, linked_list_exp = %p", $realtime,value,linked_list_exp[0:(linked_list_exp.size()-1)]); 
    //$display("%0t Complete OP_Delete_Value %0d value, linked_list_addr = %p\n", $realtime,value,linked_list_addr[0:(linked_list_addr.size()-1)]); 
end
endtask  
    
task delete_at_index (input integer addr); 
begin
    $display("%0t OP_Delete_At_Index %0d index", $realtime,addr);
    i = 0; 
    @(posedge (clk));
    #1 
    op = OP_Delete_At_Index;  
    addr_in = addr; 
    op_start = 1;

    wait (op_done)
    #1 
    if( addr >= linked_list_exp.size()) begin
       if(fault) begin
          $display("%0t Data delete out of bound, fault flag is asserted correctly",$realtime);
       end else begin
          $error("%0t Data delete out of bound, fault flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end
    end else if ( addr == 0 ) begin
       if(fault) begin
          $error("%0t fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end
       $display("%0t Data %0d at Front is Deleted", $realtime, linked_list_exp[0]);
       temp2 = linked_list_exp.pop_front();
       temp2 = linked_list_addr.pop_front();
    end else begin
       if(fault) begin
          $error("%0t fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end
       $display("%0t Data %0d at Index %0d is Deleted", $realtime, linked_list_exp[addr],addr);
       linked_list_exp.delete(addr);
       linked_list_addr.delete(addr);
    end
    if(linked_list_exp.size() == 0) begin
       if(empty) begin
          $display("%0t Queue is empty and empty flag is asserted correctly",$realtime);
       end else begin
          $error("%0t Queue is empty but empty flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end
    end else if(empty) begin
       $error("%0t Empty flag is asserted incorrectly",$realtime);
       err_cnt = err_cnt + 1;
    end
    op_start = 0;
    // icarus does not support %p concanation, so used workaround below.
    list_print_contents();
    //$display("%0t Complete OP_Delete_At_Index %0d index, linked_list_exp = %p", $realtime,addr,linked_list_exp[0:(linked_list_exp.size()-1)]); 
    //$display("%0t Complete OP_Delete_At_Index %0d index, linked_list_addr = %p\n", $realtime,addr,linked_list_addr[0:(linked_list_addr.size()-1)]); 
end
endtask  

task insert_at_index (input integer addr, input integer value); 
begin 
    $display("%0t OP_Insert_At_Index %0d index, %0d value", $realtime,addr,value);
    i = 0; 
    @(posedge (clk));
    #1 
    op = OP_Insert_At_Index;  
    addr_in = addr;
    data_in = value;
    op_start = 1; 
    wait (op_done)
    #1 
    if(linked_list_exp.size() >= DUT_MAX_NODE) begin
       if(!fault) begin
          $error("%0t Fault flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end else begin
          $display("%0t Fault flag is asserted correctly",$realtime);
       end
    end else if( addr == 0 ) begin
       if(fault) begin
          $error("%0t Fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end 
       linked_list_exp.push_front(value);
       find_next_addr(next);
       linked_list_addr.push_front(next);
       $display("%0t Data Written to Front : %0d",$realtime,value);
    end else if ( addr >= linked_list_exp.size() ) begin
       if(fault) begin
          $error("%0t Fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end 
       linked_list_exp.push_back(value);
       find_next_addr(next);
       linked_list_addr.push_back(next);
       $display("%0t Data Written to Back : %0d",$realtime,value);
    end else begin
       if(fault) begin
          $error("%0t Fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end 
       linked_list_exp.insert(addr, value);
       find_next_addr(next);
       linked_list_addr.insert(addr, next);
       $display("%0t Data Written to Index %0d : %0d",$realtime,addr,value);
    end
    if(linked_list_exp.size() >=  (DUT_MAX_NODE)) begin
       if(full) begin
          $display("%0t Queue is full and full flag is asserted correctly",$realtime);
       end else begin
          $error("%0t Queue is full but full flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end
    end else if(full) begin
       $error("%0t Full flag is asserted incorrectly",$realtime);
       err_cnt = err_cnt + 1; 
    end
    op_start = 0;
    // icarus does not support %p concanation, so used workaround below.
    list_print_contents();
    //$display("%0t Complete OP_Insert_At_Index %0d index %0d value, linked_list_exp = %p", $realtime,addr,value,linked_list_exp[0:(linked_list_exp.size()-1)]); 
    //$display("%0t Complete OP_Insert_At_Index %0d index %0d value, linked_list_addr = %p\n", $realtime,addr,value,linked_list_addr[0:(linked_list_addr.size()-1)]); 
end
endtask

task delete_at_addr (input int addr); 
begin
    $display("%0t OP_Delete_At_Addr %0d Addr", $realtime,addr);
    i = 0; 
    @(posedge (clk));
    #1 
    op = OP_Delete_At_Addr;  
    addr_in = addr; 
    op_start = 1;
    pre_head = head;
    pre_tail = tail;

    wait (op_done)
    #1 
    if( addr >= ADDR_NULL) begin
       if(fault) begin
          $display("%0t Data delete out of bound, fault flag is asserted correctly",$realtime);
       end else begin
          $error("%0t Data delete out of bound, fault flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end
    end else if ( addr == pre_head ) begin
       if(fault) begin
          $error("%0t fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end
       $display("%0t Data %0d at Front is Deleted", $realtime, linked_list_exp[0]);
       temp2 = linked_list_exp.pop_front();
       temp2 = linked_list_addr.pop_front();
   //  end else if ( addr == pre_tail ) begin
   //     if(fault) begin
   //        $error("%0t fault flag is asserted incorrectly",$realtime);
   //        err_cnt = err_cnt + 1;
   //     end
   //     $display("%0t Data %0d at Back is Deleted", $realtime, linked_list_exp[0]);
   //     temp2 = linked_list_exp.pop_back();
   //     temp2 = linked_list_addr.pop_back();
    end else begin
       temp = {};
      //  for (int j  = 0; j <1; j = j+1) begin
      //    temp = (linked_list_addr.find_first_index(x) with (x == addr));
      //  end
       find_first_index(addr);
       if (temp.size() == 0) begin
           if(!fault) begin
              $error("%0t Fault flag is not asserted",$realtime);
              err_cnt = err_cnt + 1;
           end else begin
              $display("%0t Fault flag is asserted correctly",$realtime);
           end       
       end else begin
          $display("%0t Data %0d at Addr %0d is Deleted", $realtime, linked_list_exp[temp[0]],linked_list_addr[temp[0]]);
          linked_list_exp.delete(temp[0]);
          linked_list_addr.delete(temp[0]);
       end
    end
    if(linked_list_exp.size() == 0) begin
       if(empty) begin
          $display("%0t Queue is empty and empty flag is asserted correctly",$realtime);
       end else begin
          $error("%0t Queue is empty but empty flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end
    end else if(empty) begin
       $error("%0t Empty flag is asserted incorrectly",$realtime);
       err_cnt = err_cnt + 1;
    end
    op_start = 0;
    // icarus does not support %p concanation, so used workaround below.
    list_print_contents();
    //$display("%0t Complete OP_Delete_At_Addr %0d addr, linked_list_exp = %p", $realtime,addr,linked_list_exp[0:(linked_list_exp.size()-1)]); 
    //$display("%0t Complete OP_Delete_At_Addr %0d addr, linked_list_addr = %p\n", $realtime,addr,linked_list_addr[0:(linked_list_addr.size()-1)]); 
end
endtask  

task insert_at_addr (input int addr, input integer value); 
begin 
    $display("%0t OP_Insert_At_Addr %0d addr, %0d value", $realtime,addr,value);
    i = 0; 
    @(posedge (clk));
    #1 
    op = OP_Insert_At_Addr;  
    addr_in = addr;
    data_in = value;
    op_start = 1; 
    pre_head = head;
    pre_tail = tail;
    wait (op_done)
    #1 
    if(linked_list_exp.size() >= DUT_MAX_NODE) begin
       if(!fault) begin
          $error("%0t Fault flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end else begin
          $display("%0t Fault flag is asserted correctly",$realtime);
       end
    end else if( addr == pre_head ) begin
       if(fault) begin
          $error("%0t Fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end 
       linked_list_exp.push_front(value);
       find_next_addr(next);
       linked_list_addr.push_front(next);
       $display("%0t Data Written to Front : %0d",$realtime,value);
    end else if( addr == pre_tail ) begin
       if(fault) begin
          $error("%0t Fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end 
       linked_list_exp.insert(linked_list_exp.size()-1, value);
       find_next_addr(next);
       linked_list_addr.insert(linked_list_addr.size()-1, next);
       $display("%0t Data Written to Back : %0d",$realtime,value);
    end else if ( addr >= ADDR_NULL ) begin
       if(fault) begin
          $error("%0t Fault flag is asserted incorrectly",$realtime);
          err_cnt = err_cnt + 1;
       end 
       linked_list_exp.push_back(value);
       find_next_addr(next);
       linked_list_addr.push_back(next);
       $display("%0t Data Written to Back : %0d",$realtime,value);
    end else begin
       temp = {};
      //  for (int j  = 0; j <1; j = j+1) begin
      //    temp = (linked_list_addr.find_first_index(x) with (x == addr));
      //  end
       find_first_index(addr);
       if (temp.size() == 0) begin
           if(!fault) begin
              $error("%0t Fault flag is not asserted",$realtime);
              err_cnt = err_cnt + 1;
           end else begin
              $display("%0t Fault flag is asserted correctly",$realtime);
           end       
       end else begin
          linked_list_exp.insert(temp[0], value);
          find_next_addr(next);
          linked_list_addr.insert(temp[0], next);
          $display("%0t Data Written to Addr %0d : %0d",$realtime,addr,value);
       end      
    end
    if(linked_list_exp.size() >=  (DUT_MAX_NODE)) begin
       if(full) begin
          $display("%0t Queue is full and full flag is asserted correctly",$realtime);
       end else begin
          $error("%0t Queue is full but full flag is not asserted",$realtime);
          err_cnt = err_cnt + 1;
       end
    end else if(full) begin
       $error("%0t Full flag is asserted incorrectly",$realtime);
       err_cnt = err_cnt + 1; 
    end
    op_start = 0;
    // icarus does not support %p concanation, so used workaround below.
    list_print_contents();
    //$display("%0t Complete OP_Insert_At_Addr %0d addr %0d value, linked_list_exp = %p", $realtime,addr,value,linked_list_exp[0:(linked_list_exp.size()-1)]);
    //$display("%0t Complete OP_Insert_At_Addr %0d addr %0d value, linked_list_addr = %p\n", $realtime,addr,value,linked_list_addr[0:(linked_list_addr.size()-1)]); 
end
endtask

task direct_index_op_test();
begin
    $display("\n======================================");
    $display("Direct Index Op Test");
    $display("======================================");
    //DIRECT TEST Index Mode
    rst = 1'b1;
    #100
    rst = 1'b0;
    linked_list_exp = {};
    linked_list_addr = {};
    insert_at_index(0,3);
    insert_at_index(0,0);
    #100
    insert_at_index(4,5); 
    insert_at_index(0,6);
    insert_at_index(0,7);  
    insert_at_index(1,3); 
    insert_at_index(2,4);
    insert_at_index(ADDR_NULL,3);
    insert_at_index(ADDR_NULL,4);
    insert_at_index(ADDR_NULL,1);
    insert_at_index(0,3);
    #200
    read_n(linked_list_exp.size());
    #500
    delete_value(7);
    delete_at_index(0);
    delete_at_index(0);
    delete_value(2);  
    delete_value(4);
    delete_at_index(0);
    read_n(linked_list_exp.size());
    delete_at_index(7);
    delete_at_index(length-1);
    delete_at_index(length-1);
    delete_at_index(0);     
    delete_at_index(0); 
    delete_at_index(0);    
    #500;
end
endtask

task direct_addr_op_test();
begin
    //DIRECT TEST Index Mode
    $display("\n======================================");
    $display("Direct Address Op Test");
    $display("======================================");
    rst = 1'b1;
    #100
    rst = 1'b0;
    linked_list_exp = {};
    linked_list_addr = {};
    insert_at_addr(head,3);
    insert_at_addr(head,0);
    #100
    insert_at_addr(0,5); 
    insert_at_addr(head,6);
    insert_at_addr(linked_list_addr[2],7);  
    insert_at_addr(tail,3); 
    insert_at_addr(head,4);
    insert_at_addr(ADDR_NULL,3);
    insert_at_addr(ADDR_NULL,4);
    insert_at_addr(ADDR_NULL,1);
    insert_at_addr(0,3);
    #200
    read_n(linked_list_exp.size());
    #500
    delete_value(7);
    delete_at_addr(0);
    delete_at_addr(head);
    delete_value(2);  
    delete_value(4);
    read_n(linked_list_exp.size());
    delete_at_addr(head);
    delete_at_addr(7);
    delete_at_addr(tail);
    delete_at_addr(tail);
    delete_at_addr(0);        
    #500;
end
endtask

initial begin
    string vcdfile;
    int vcdlevel;
    int seed;

    rst = 1'b1;
    if ($value$plusargs("VCDFILE=%s",vcdfile))
        $dumpfile(vcdfile);
    if ($value$plusargs("VCDLEVEL=%d",vcdlevel))
        $dumpvars(vcdlevel,tb);
    if ($value$plusargs("SEED=%d",seed)) begin
        temp2 = $urandom(seed);
        $display("Seed = %d",seed);
    end
    
    direct_index_op_test();
    
    #1000;
    
    direct_addr_op_test();
    
    //DIRECT TEST Index Mode
    
    if (err_cnt > 0) begin
        $display("\n%0t TEST FAILED",$realtime);
        $display("Error count = %d\n", err_cnt);
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
