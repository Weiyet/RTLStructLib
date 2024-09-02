`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 07/11/2024 10:23:52 PM
// Module Name: tb
// Description: Supported Operation 
//             1. Read_n(Count) 
//             2. Delete_Value(data_in)
//             3. Delete_Addr(addr_in) 
//             4. Insert(addr_in, data_in)
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
    localparam TB_SIM_TIMEOUT = 500000;

localparam ADDR_NULL = (DUT_MAX_NODE+1);

localparam OP_Read = 2'b00;
localparam OP_Insert = 2'b01;
localparam OP_Delete_value = 2'b10;
localparam OP_Delete_addr = 2'b11;

// input 
reg clk = 0;
reg rst = 0;
reg [DUT_DATA_WIDTH-1:0] data_in = 0; 
reg [ADDR_WIDTH-1:0] addr_in = 0; 
reg [1:0] op = 0;
reg op_start = 0;
// output
wire [DUT_DATA_WIDTH-1:0] data_out;
wire op_done;
wire [ADDR_WIDTH-1:0] next_node_addr; 
wire [ADDR_WIDTH-1:0] head;
wire [ADDR_WIDTH-1:0] tail;
wire full;
wire empty;
wire fault; 
 
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
        /*output reg [ADDR_WIDTH-1:0]*/  .head(head), // Addr of head
        /*output reg [ADDR_WIDTH-1:0]*/  .tail(tail), // Addr of tail
        /*output wire*/ .full(full), 
        /*output wire*/ .empty(empty),
        /*output reg*/  .fault(fault) // Invalid Errors 
    );
    
always #(TB_CLK_PERIOD/2) clk = ~clk; 

integer linked_list_exp[$];    
integer data_wr[$];
integer i = 0;

task read_n(input integer count); 
begin
    i = 0;
    @(posedge (clk));
    #1 
    op = OP_Read;  
    op_start = 1;
    addr_in = head;
    i = i + 1;
    while (i<count) begin  
        @(posedge (clk));
        #1 
        if(op_done) begin
            op = OP_Read;  
            op_start = 1;
            addr_in = next_node_addr;
            i = i + 1;
        end
    end
    @(posedge (clk))
    #1 
    op_start = 0;
end
endtask  

task delete_value(input integer value); 
begin
    i = 0; 
    @(posedge (clk));
    #1 
    op = OP_Delete_value;  
    data_in = value;
    op_start = 1;
    wait (op_done)
    #1 
    op_start = 0;
end
endtask  
    
task delete_addr(input integer addr); 
begin
    i = 0; 
    @(posedge (clk));
    #1 
    op = OP_Delete_addr;  
    addr_in = addr; 
    op_start = 1;
    wait (op_done)
    #1 
    op_start = 0;
end
endtask  

task insert(input integer addr, input integer value); 
begin 
    i = 0; 
    @(posedge (clk));
    #1 
    op = OP_Insert;  
    addr_in = addr;
    data_in = value;
    op_start = 1;  
    wait (op_done)
    #1 
    op_start = 0;
end
endtask

initial begin
    rst = 1'b1;
    #100
    rst = 1'b0;
    insert(head,3);
    insert(head,3);
    #100
    insert(head,5);
    insert(head,6);
    insert(head,7);
    insert(ADDR_NULL,3);
    insert(ADDR_NULL,4);
    insert(ADDR_NULL,3);
    insert(ADDR_NULL,3);
    insert(ADDR_NULL,3);
    #200
    delete_addr(head);
    delete_addr(head);
    delete_addr(head);  
    delete_addr(head);
    delete_addr(head);
    delete_addr(head);
    delete_addr(tail);
    delete_addr(head);
    delete_addr(head);        
//    read_n(3);
    #500
//    delete_value(linked_list_exp[2]);
    $stop; 
end

initial begin
#(TB_SIM_TIMEOUT)
$stop; 
end

endmodule
