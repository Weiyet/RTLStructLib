
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 06/25/2024 08:46:52 PM
// Module Name: linked_list
// Description: linked_list
// 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////


module linked_list #(
    parameter DATA_WIDTH = 8, // Data Width
    parameter MAX_NODE = 8  // Maximum number of nodes stored
    )(
        input rst,
        input sync_rst,
        input clk,
        input data_in, 
        input addr_in,
        input [1:0] op, // 0: Read(addr_in); 1: Delete_Value(data_in); 2: Push_Back(data_in); 3: Push_front(data_in)
        input op_start, 
        output reg [DATA_WIDTH-1:0] data_out,
        output reg op_done,
        output wire next_node_addr, // Addr of next node
        // status 
        output reg head, // Addr of head
        output reg tail, // Addr of tail
        output wire full, 
        output wire empty,
        output reg fault, // Invalid Errors 
    );

    localparam ADDR_WIDTH = $clog2(MAX_NODE+1); // Reserve {ADDR_WIDTH(1'b1)} as NULL/INVALID ADDR.

    typedef struct {  
        reg [DATA_WIDTH-1:0] data; // Dual port RAM
        reg [ADDR_WIDTH-1:0] next_node_addr; // Dual port RAM 
        reg valid;
    } node_st;
    
    node_st node [0:MAX_NODE-1];
    wire [MAX_NODE-1:0] valid_bits;
    wire op_is_read; 
    wire op_is_push_back;
    wire op_is_delete;
    wire op_is_push_front;
    reg [ADDR_WIDTH-1:0] pre_ptr [0:1]; 
    reg [2:0] state;
    reg [2:0] next_state;
    reg wr_req;
    reg rd_req;
    reg valid_rd_buf;
    reg valid_wr; 
    reg [ADDR_WIDTH-1:0] next_addr_rd_buf;
    reg [DATA_WIDTH-1:0] data_rd_buf;
    reg [ADDR_WIDTH-1:0] target_idx; 
    reg [ADDR_WIDTH-1:0] next_node_addr_idx;
    reg [ADDR_WIDTH-1:0] next_node_addr_in;
    
    localparam IDLE = 3'b000;
    localparam EXECUTE = 3'b010;
    localparam FIND_VALUE = 3'b011;
    localparam FAULT = 3'b001;

    assign op_is_read = op == 2'd0 & start;
    assign op_is_delete = op == 2'd1 & start;
    assign op_is_push_back = op == 2'd2 & start; 
    assign op_is_push_front = op == 2'd3 & start;

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < MAX_NODE; i = i+1) begin
                node[i].data <= {DATA_WIDTH{1'b0}};
                node[i].valid <= 1'b0;
                node[i].next_node_addr <= {ADDR_WIDTH{1'b0}};
            end
        end else if (wr_req) begin  
            node[target_idx].data <= data_in;
            node[target_idx].valid <= 1'b1;
            if (empty) begin
                node[next_node_addr_idx].next_node_addr <= next_node_addr_in;  // FIXME
            end
        end 
    end

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            state <= 3'b0;
        end else begin
            state <= next_state; 
        end
    end
    
    // //op_done
    always @ (*) begin
        op_done <= 1'b0;
        rd_req <= 1'b0;
        wr_req <= 1'b0;
        target_idx <= {ADDR_WIDTH{1'b0}};
        next_node_addr_idx <= {ADDR_WIDTH{1'b0}};
        fault <= 1'b0;
        case(state)
            IDLE: begin
                if (op_is_push_back) begin  //WR TAIL.next addr
                   if(full) begin
                       next_state <= FAULT;
                   end else begin
                       wr_req <= 1'b1;
                       target_idx <= find_next_ptr(valid_bits);
                       valid_wr <= 1'b1;
                       next_node_addr_idx <= tail;
                       next_node_addr_in <= find_next_ptr(valid_bits) ;
                       next_state <= EXECUTE;
                   end
                end else if (op_is_push_front) begin
                   if(full) begin
                       next_state <= FAULT;
                   end else begin
                       wr_req <= 1'b1;
                       target_idx <= find_next_ptr(valid_bits);
                       valid_wr <= 1'b1;
                       next_node_addr_idx <= find_next_ptr(valid_bits);
                       next_node_addr_in <= head;
                       next_state <= EXECUTE;
                   end
                end else if (op_is_read) begin
                   rd_req <= 1'b1;
                   target_idx <= addr_in;
                   next_state <= EXECUTE;
                end else if (op_is_delete) begin 
                   rd_req <= 1'b1;
                   target_idx <= head;
                   next_state <= FIND_VALUE;
                end
            end
            EXECUTE: begin
                op_done <= 1'b1;
                next_state <= IDLE;
            end 
            FIND_VALUE: begin
                if(data_rd_buf == data_in) begin  //FIXME case for if pre_ptr[0] is head; if next is NULL pointer return FAULT.
                    wr_req <= 1'b1;
                    target_idx <= pre_ptr[0];
                    valid_wr <= 1'b0;
                    next_node_addr_idx <= pre_ptr[1]; 
                    next_node_addr_in <= next_addr_rd_buf;
                    next_state <= EXECUTE;
                end else begin
                   rd_req <= 1'b1;
                   target_idx <= next_addr_rd_buf;
                   next_state <= CHECK_VALUE;
                end
            end
            FAULT: begin
                fault <= 1'b1;
                op_done <= 1'b1;
                next_state <= IDLE;
            end
       endcase
    end

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
           data_out <= {DATA_WIDTH{1'b0}};
        end else if (rd_req) begin
           data_out <= node[target_idx].data; 
        end
    end

    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            //pre_ptr <= {ADDR_WIDTH{1'b0}};
            data_rd_buf <= {DATA_WIDTH{1'b0}};
            valid_rd_buf <= 1'b0;
            next_addr_rd_buf= {ADDR_WIDTH{1'b0}};
        end else if (rd_req) begin
            //pre_ptr <= target_idx;
            data_rd_buf <=  node[target_idx].data;
            valid_rd_buf <= node[target_idx].valid;
            next_addr_rd_buf <= node[target_idx].next_node_addr;
        end
    end
    
    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            pre_ptr[1:0] <= {2*ADDR_WIDTH{1'b0}};
        end else if (rd_req | wr_req) begin
            pre_ptr[1:0] <= {pre_ptr[0],target_idx};
        end
    end
    
    assign valid = valid_rd_buf;
    assign next_node_addr = next_addr_rd_buf;

    genvar j;
    // Status
    generate 
        for (j = 0; j < MAX_NODE; j = j+1) begin
            assign valid_bits[j] = node[j].valid;
        end
    endgenerate

    assign full = & valid_bits;
    assign empty = ~(| valid_bits);
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            head <= {ADDR_WIDTH{1'b0}};
        end else if (op_is_push_front) begin
            head <= target_idx;
        end    
    end
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            tail <= {ADDR_WIDTH{1'b0}};
        end else if (op_is_push_back) begin
            tail <= target_idx;
        end    
    end
    
    function bit [ADDR_WIDTH-1:0] find_next_ptr(input bit [MAX_NODE-1:0] valid_bits);
        int done;
        done = 0;
        find_next_ptr = 0;
        for (int i = 1; i < MAX_NODE ; i = i+1) begin
            if(valid_bits[i] == 0 & done == 0) begin
                find_next_ptr = i; 
                done = 1;
            end 
        end
    endfunction

endmodule
