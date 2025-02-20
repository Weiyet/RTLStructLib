`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 09/10/2024 08:46:52 PM
// Last Update: 02/20/2025 10:17 PM
// Module Name: doubly_linked_list
// Description: Supported Operation 
//             0. Read_Addr(addr_in) -> data_out 
//             1. Insert_Addr(addr_in, data_in) 
//             5. Insert_Index(addr_in, data_in)
//             2. Delete_Value(data_in)
//             3. Delete_Addr(addr_in)
//             7. Delete_Index(addr_in) 
// Additional Comments: .
// 
//////////////////////////////////////////////////////////////////////////////////


module doubly_linked_list #(
    parameter DATA_WIDTH = 8, // Data Width
    parameter MAX_NODE = 8  // Maximum number of nodes stored
    )(
        input rst,
        input clk,
        input [DATA_WIDTH-1:0] data_in, 
        input [ADDR_WIDTH-1:0] addr_in, // index of element
        input [2:0] op, // 0: Read(addr_in); 1: Delete_value(data_in); 2: Push_back(data_in); 3: Push_front(data_in)
        input op_start, 
        output reg op_done,
        output reg [DATA_WIDTH-1:0] data_out,
        output reg [ADDR_WIDTH-1:0] pre_node_addr, // Addr of pre node
        output reg [ADDR_WIDTH-1:0] next_node_addr, // Addr of next node
        // status 
        output reg [ADDR_WIDTH-1:0] length,
        output reg [ADDR_WIDTH-1:0] head, // Addr of head
        output reg [ADDR_WIDTH-1:0] tail, // Addr of tail
        output wire full, 
        output wire empty,
        output reg fault 
    );

    localparam ADDR_WIDTH = $clog2(MAX_NODE+1); // Reserve {ADDR_WIDTH(1'b1)} as NULL/INVALID ADDR.
    localparam NODE_WIDTH = $clog2(MAX_NODE);
    localparam ADDR_NULL = (MAX_NODE);

    // yosys does not support sv typedef
    // typedef struct {  
    //     reg [DATA_WIDTH-1:0] data; // RAM
    //     reg [ADDR_WIDTH-1:0] next_node_addr; // RAM 
    //     reg [ADDR_WIDTH-1:0] pre_node_addr; // RAM
    //     reg valid; // Register
    // } node_st;
    
    //node_st node [0:MAX_NODE-1];
    reg [DATA_WIDTH-1:0] node_data [0:MAX_NODE-1]; // RAM
    reg [ADDR_WIDTH-1:0] node_next_node_addr [0:MAX_NODE-1]; // RAM
    reg [ADDR_WIDTH-1:0] node_pre_node_addr [0:MAX_NODE-1]; // RAM
    reg node_valid [0:MAX_NODE-1]; // Register

    wire [MAX_NODE-1:0] valid_bits;
    wire op_is_read; 
    wire op_is_insert_at_addr;
    wire op_is_insert_at_index;
    wire op_is_delete_by_addr;
    wire op_is_delete_by_index;
    wire op_is_delete_by_value;
 //   wire addr_match;
    wire ascending; 
    wire [ADDR_WIDTH-1:0] head_idx_sel;
    wire [ADDR_WIDTH-1:0] tail_idx_sel;
    wire addr_overflow;
    reg [NODE_WIDTH-1:0] index;
    reg [ADDR_WIDTH-1:0] cur_ptr; 
    reg [ADDR_WIDTH-1:0] pre_ptr; 
    //reg [ADDR_WIDTH-1:0] head; // Addr of head
    //reg [ADDR_WIDTH-1:0] tail; // Addr of tail
    reg [2:0] state;
    reg [2:0] next_state;
    reg wr_req;
    reg rd_req;
    reg valid_rd_buf;
    reg valid_wr; 
    reg [ADDR_WIDTH-1:0] next_addr_rd_buf;
    reg [ADDR_WIDTH-1:0] pre_addr_rd_buf;
    reg [DATA_WIDTH-1:0] data_rd_buf;
    reg [ADDR_WIDTH-1:0] target_idx; 
    reg [ADDR_WIDTH-1:0] next_node_addr_idx;
    reg [ADDR_WIDTH-1:0] next_node_addr_in;
    reg [ADDR_WIDTH-1:0] pre_node_addr_idx;
    reg [ADDR_WIDTH-1:0] pre_node_addr_in;

    integer i;
    
    localparam IDLE = 3'b000;
    localparam FIND_ADDR = 3'b001;
    localparam FIND_VALUE = 3'b010;
    localparam FIND_INDEX = 3'b110;
    localparam INSERT_STG1 = 3'b011;
    localparam FAULT = 3'b101;
    localparam EXECUTE = 3'b100;

    assign op_is_read = op[2:0] == 3'd0 & op_start;
    assign op_is_insert_at_index = op[2:0] == 3'd5 & op_start; 
    assign op_is_insert_at_addr = op[2:0] == 3'd1 & op_start; 
    assign op_is_delete_by_value = op[2:0] == 3'd2 & op_start;
    assign op_is_delete_by_index = op[2:0] == 3'd7 & op_start; 
    assign op_is_delete_by_addr = op[2:0] == 3'd3 & op_start;

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < MAX_NODE; i = i+1) begin
                node_data[i] <= {DATA_WIDTH{1'b0}};
                node_valid[i] <= 1'b0;
            end
        end else if (wr_req & state != INSERT_STG1 & target_idx != ADDR_NULL) begin  
            node_data[target_idx[NODE_WIDTH-1:0]] <= data_in; 
            node_valid[target_idx[NODE_WIDTH-1:0]] <= valid_wr;
        end 
    end

    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < MAX_NODE; i = i+1) begin
                node_next_node_addr[i] <= ADDR_NULL;
            end
        end else if (wr_req & next_node_addr_idx != ADDR_NULL) begin  
            node_next_node_addr[next_node_addr_idx[NODE_WIDTH-1:0]] <= next_node_addr_in;
        end 
    end
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < MAX_NODE; i = i+1) begin
                node_pre_node_addr[i] <= ADDR_NULL;
            end
        end else if (wr_req & pre_node_addr_idx != ADDR_NULL) begin  
            node_pre_node_addr[pre_node_addr_idx[NODE_WIDTH-1:0]] <= pre_node_addr_in;
        end 
    end
    
    assign head_idx_sel = op[2] ? 0 : head;
    assign tail_idx_sel = op[2] ? (length-1) : tail;
    assign addr_overflow = (op[2] & (addr_in >= length)) | (addr_in >= ADDR_NULL);
    assign ascending = (addr_in < (length << 2)); 
   
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            state <= 3'b0;
        end else begin
            state <= next_state; 
        end
    end
   
    // op_done
    always @ (*) begin
        op_done <= 1'b0;
        rd_req <= 1'b0;
        wr_req <= 1'b0;
        target_idx <= ADDR_NULL;
        valid_wr <= 1'b0;
        next_node_addr_idx <= ADDR_NULL;
        next_node_addr_in <= ADDR_NULL;
        pre_node_addr_idx <= ADDR_NULL;
        pre_node_addr_in <= ADDR_NULL;
        fault <= 1'b0;
        next_state <= IDLE;
        case(state)
            IDLE: begin
                if (op_is_insert_at_addr | op_is_insert_at_index) begin
                    if (full) begin
                        next_state <= FAULT; 
                    end else if (addr_in == head_idx_sel) begin // push_front
                        // Add new node 
                        // Next node addr of new node point to head
                        wr_req <= 1'b1;
                        target_idx <= find_next_ptr(valid_bits);
                        valid_wr <= 1'b1;
                        next_node_addr_idx <= find_next_ptr(valid_bits);
                        next_node_addr_in <= head;
                        pre_node_addr_idx <= head;
                        pre_node_addr_in <= find_next_ptr(valid_bits);
                        next_state <= EXECUTE;
                    end else if (addr_overflow) begin // push_back
                        // Add new node 
                        // Next node addr of tail point to new node
                        wr_req <= 1'b1;
                        target_idx <= find_next_ptr(valid_bits);
                        valid_wr <= 1'b1;
                        next_node_addr_idx <= tail;
                        next_node_addr_in <= find_next_ptr(valid_bits);
                        pre_node_addr_idx <= find_next_ptr(valid_bits);
                        pre_node_addr_in <= tail;
                        next_state <= EXECUTE;                        
                    end else begin
                        rd_req <= 1'b1;
                        target_idx <= op[2]? (ascending ? head : tail) : addr_in;
                        next_state <= op[2]? FIND_INDEX : FIND_ADDR;
                    end
                end else if (op_is_read) begin
                   if(empty | addr_overflow) begin 
                      next_state <= FAULT;    
                   end else begin            
                      rd_req <= 1'b1;
                      target_idx <= addr_in;
                      next_state <= EXECUTE;
                   end
                end else if (op_is_delete_by_value) begin 
                   if(empty) begin
                      next_state <= FAULT; 
                   end else begin
                      rd_req <= 1'b1;
                      target_idx <= head;
                      next_state <= FIND_VALUE;
                   end
                end else if (op_is_delete_by_addr | op_is_delete_by_index) begin 
                   if(empty | addr_overflow) begin
                      next_state <= FAULT; 
                   end else begin
                      rd_req <= 1'b1;
                      target_idx <= op[2] ? (ascending ? head : tail) : addr_in;
                      next_state <= op[2] ? FIND_INDEX : FIND_ADDR;
                   end
                end else begin
                   next_state <= IDLE;
                end
            end
            FIND_ADDR: begin // to get pre pos (pre_ptr)
                if (!valid_rd_buf) begin
                    next_state <= FAULT;     
                end else begin 
                    if(op_is_delete_by_addr) begin
                        // update curr pos to invalid
                        wr_req <= 1'b1;
                        target_idx <= cur_ptr;
                        valid_wr <= 1'b0;
                        // update next_node_addr of pre pos to next pos
                        next_node_addr_idx <= pre_addr_rd_buf; 
                        next_node_addr_in <= next_addr_rd_buf;
                        // update pre_node_addr of next post to pre pos
                        pre_node_addr_idx <= next_addr_rd_buf;
                        pre_node_addr_in <= pre_addr_rd_buf;
                        next_state <= EXECUTE; 
                    end else if (op_is_insert_at_addr) begin
                        // insert new pos 
                        wr_req <= 1'b1;
                        target_idx <= find_next_ptr(valid_bits);
                        valid_wr <= 1'b1;    
                        // update next_node_addr of curr pos to new pos
                        next_node_addr_idx <= pre_addr_rd_buf; 
                        next_node_addr_in <= find_next_ptr(valid_bits);  
                        // update next_node_addr of next pos to neew pos
                        pre_node_addr_idx <= find_next_ptr(valid_bits);
                        pre_node_addr_in <= pre_addr_rd_buf;
                        next_state <= INSERT_STG1;   
                    end          
                end 
            end
            FIND_INDEX: begin 
                if (!valid_rd_buf) begin
                    next_state <= FAULT;     
                end else if (addr_in == index) begin 
                    if(op_is_delete_by_index) begin
                        // update cur pos to invalid
                        wr_req <= 1'b1;
                        target_idx <= cur_ptr;
                        valid_wr <= 1'b0;
                        // update next_node_addr of pre pos to next pos
                        next_node_addr_idx <= pre_addr_rd_buf; 
                        next_node_addr_in <= next_addr_rd_buf;
                        // update pre_node_addr of next post to pre pos
                        pre_node_addr_idx <= next_addr_rd_buf;
                        pre_node_addr_in <= pre_addr_rd_buf;
                        next_state <= EXECUTE; 
                    end else if (op_is_insert_at_index) begin
                        // insert new pos 
                        wr_req <= 1'b1;
                        target_idx <= find_next_ptr(valid_bits);
                        valid_wr <= 1'b1;    
                        // update next_node_addr of curr pos to new pos
                        next_node_addr_idx <= pre_addr_rd_buf; 
                        next_node_addr_in <= find_next_ptr(valid_bits);  
                        // update next_node_addr of next pos to neew pos
                        pre_node_addr_idx <= find_next_ptr(valid_bits);
                        pre_node_addr_in <= pre_addr_rd_buf;
                        next_state <= INSERT_STG1;         
                    end 
                end else if ((ascending & index >= (length - 1)) | (!ascending & index == 0)) begin
                    next_state <= FAULT;            
                end else begin
                   rd_req <= 1'b1;
                   target_idx <= ascending ? next_addr_rd_buf : pre_addr_rd_buf;
                   next_state <= FIND_INDEX;     
                end
            end
            FIND_VALUE: begin  
                if(data_rd_buf == data_in) begin 
                    // update curr pos to invalid
                    wr_req <= 1'b1;
                    target_idx <= cur_ptr;
                    valid_wr <= 1'b0;
                    // update next_node_addr of pre pos to next pos
                    next_node_addr_idx <= pre_ptr; 
                    next_node_addr_in <= next_addr_rd_buf;
                    // update pre_node_addr of next pos to pre pos
                    pre_node_addr_idx <= next_addr_rd_buf; 
                    pre_node_addr_in <= pre_ptr;
                    next_state <= EXECUTE;    
                end else if (index >= (length - 1)) begin
                    next_state <= FAULT; 
                end else begin
                   rd_req <= 1'b1;
                   target_idx <= next_addr_rd_buf;
                   next_state <= FIND_VALUE;
                end
            end 
            INSERT_STG1: begin
                wr_req <= 1'b1; 
                next_node_addr_idx <= cur_ptr; //new inserted node
                next_node_addr_in <= pre_ptr;
                pre_node_addr_idx <= pre_ptr; 
                pre_node_addr_in <= cur_ptr;
                next_state <= EXECUTE;  
            end
            EXECUTE: begin
                op_done <= 1'b1;
                fault <= op_is_read & !valid_rd_buf;
                next_state <= IDLE;
            end 
            FAULT: begin
                fault <= 1'b1;
                op_done <= 1'b1;
                next_state <= IDLE;
            end 
            default: begin
                next_state <= IDLE;
            end
       endcase
    end

    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            index <= 0;
        end else if (state == FIND_VALUE) begin
            index <= index + 1;
        end else if (state == FIND_INDEX) begin
            index <= ascending ? (index + 1) : (index - 1);
        end else if (!ascending & next_state == FIND_INDEX) begin
            index <= length - 1; 
        end else begin
            index <= 0;
        end
    end

    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            data_rd_buf <= {DATA_WIDTH{1'b0}};
            valid_rd_buf <= 1'b0;
            next_addr_rd_buf <= {ADDR_WIDTH{1'b0}};
            pre_addr_rd_buf <= {ADDR_WIDTH{1'b0}};
        end else if (rd_req) begin
            data_rd_buf <=  node_data[target_idx];
            valid_rd_buf <= node_valid[target_idx];
            next_addr_rd_buf <= node_next_node_addr[target_idx];
            pre_addr_rd_buf <= node_pre_node_addr[target_idx];
        end
    end
    
    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            data_out <= {DATA_WIDTH{1'b0}};
            next_node_addr <= ADDR_NULL;
            pre_node_addr <= ADDR_NULL;
        end else if (op_is_read & (next_state == EXECUTE)) begin
            data_out <=  node_data[target_idx];
            next_node_addr <= (addr_in == tail) ? ADDR_NULL : node_next_node_addr[target_idx];
            pre_node_addr <= (addr_in == head) ? ADDR_NULL : node_pre_node_addr[target_idx];
        end
    end
   
    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            cur_ptr <= ADDR_NULL;
            pre_ptr <= ADDR_NULL;
        end else if(next_state == IDLE) begin
            cur_ptr <= ADDR_NULL;
            pre_ptr <= ADDR_NULL;
        end
        else if (rd_req | wr_req) begin
            cur_ptr <= target_idx;
            pre_ptr <= cur_ptr;
        end
    end

    genvar j;
    // Status
    generate 
        for (j = 0; j < MAX_NODE; j = j+1) begin
            assign valid_bits[j] = node_valid[j];
        end
    endgenerate

    assign full = & valid_bits;
    assign empty = ~(| valid_bits);
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            head <= ADDR_NULL;
        end else if ((op_is_insert_at_addr | op_is_insert_at_index) & ((addr_in == head_idx_sel) | empty) & (next_state == EXECUTE)) begin //INVALID addr
            head <= find_next_ptr(valid_bits);
        end else if ((op_is_delete_by_value | op_is_delete_by_addr | op_is_delete_by_index) & (next_state == EXECUTE) & (length == 1)) begin
            head <= ADDR_NULL;
        end else if ((op_is_delete_by_addr | op_is_delete_by_index) & (addr_in == head_idx_sel)  & (next_state == EXECUTE)) begin
            head <= next_addr_rd_buf;
        end else if (op_is_delete_by_value & (cur_ptr == head) & (next_state == EXECUTE)) begin
            head <= next_addr_rd_buf;
        end
    end 
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            tail <= ADDR_NULL;
        end else if ((op_is_insert_at_addr | op_is_insert_at_index) & (addr_overflow | empty) & (next_state == EXECUTE)) begin
            tail <= find_next_ptr(valid_bits);
        end else if ((op_is_delete_by_value | op_is_delete_by_addr | op_is_delete_by_index) & (next_state == EXECUTE) & (length == 1)) begin
            tail <= ADDR_NULL;
        end else if ((op_is_delete_by_addr | op_is_delete_by_index) & (addr_in == tail_idx_sel) & (next_state == EXECUTE)) begin
            tail <= pre_ptr; 
        end else if (op_is_delete_by_value & (cur_ptr == tail) & (next_state == EXECUTE)) begin
            tail <= pre_ptr;
        end
    end
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            length <= 0;
        end else if ((op_is_insert_at_addr | op_is_insert_at_index) & (next_state == EXECUTE)) begin
            length <= length + 1;
        end else if ((op_is_delete_by_addr | op_is_delete_by_index)& (next_state == EXECUTE)) begin
            length <= length - 1;
        end else if (op_is_delete_by_value & (next_state == EXECUTE)) begin
            length <= length - 1;
        end
    end
    
    function integer find_next_ptr(input integer valid_bits);
        integer done;
        done = 0;
        find_next_ptr = 0;
        for (i = 0; i < MAX_NODE ; i = i+1) begin
            if(valid_bits[i] == 0 & done == 0) begin
                find_next_ptr = i; 
                done = 1;
            end 
        end
    endfunction

endmodule
