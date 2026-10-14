`timescale 1ns / 1ps
// Circular doubly linked list, following the Singly/Doubly operation codes.
// Occupied nodes always form one ring; index zero is the designated head.
module circular_linked_list #(
    parameter DATA_WIDTH = 8,
    parameter MAX_NODE = 8,
    localparam ADDR_WIDTH = (MAX_NODE > 0) ? $clog2(MAX_NODE+1) : 1
)(
    input wire rst,
    input wire clk,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [ADDR_WIDTH-1:0] addr_in,
    input wire [2:0] op,
    input wire op_start,
    output wire op_done,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [ADDR_WIDTH-1:0] pre_node_addr,
    output reg [ADDR_WIDTH-1:0] next_node_addr,
    output reg [ADDR_WIDTH-1:0] length,
    output reg [ADDR_WIDTH-1:0] head,
    output reg [ADDR_WIDTH-1:0] tail,
    output wire full,
    output wire empty,
    output wire fault,
    output wire busy
);
    localparam [ADDR_WIDTH-1:0] ADDR_NULL = MAX_NODE;
    localparam READ_ADDR = 3'd0, INSERT_ADDR = 3'd1, DELETE_VALUE = 3'd2,
               DELETE_ADDR = 3'd3, INSERT_INDEX = 3'd5, DELETE_INDEX = 3'd7;
    localparam IDLE = 3'd0, DISPATCH = 3'd1, WALK_INDEX = 3'd2,
               WALK_VALUE = 3'd3, INSERT_NODE = 3'd4, DELETE_NODE = 3'd5,
               COMPLETE = 3'd6;

    reg [DATA_WIDTH-1:0] node_data [0:MAX_NODE-1];
    reg [ADDR_WIDTH-1:0] node_next_node_addr [0:MAX_NODE-1];
    reg [ADDR_WIDTH-1:0] node_pre_node_addr [0:MAX_NODE-1];
    reg [MAX_NODE-1:0] node_valid;
    reg [2:0] state, request_op;
    reg [ADDR_WIDTH-1:0] request_addr, cursor, walk_index, target, new_node;
    reg [DATA_WIDTH-1:0] request_data;
    reg append_node, operation_fault;

    // Match the existing lists' deterministic lowest-free-address allocation.
    reg [ADDR_WIDTH-1:0] free_node;
    integer candidate;
    always @(*) begin
        free_node = ADDR_NULL;
        for (candidate = MAX_NODE-1; candidate >= 0; candidate = candidate - 1)
            if (!node_valid[candidate])
                free_node = candidate;
    end

    assign op_done = !rst && state == COMPLETE;
    assign busy = !rst && state != IDLE && state != COMPLETE;
    assign fault = op_done && operation_fault;
    assign full = (length == MAX_NODE);
    assign empty = (length == 0);

    generate
        if (DATA_WIDTH < 1 || MAX_NODE < 1) begin : gen_invalid_parameters
            initial $fatal(1, "Invalid circular_linked_list parameters");
        end
    endgenerate

    integer item;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            request_op <= 0;
            request_addr <= ADDR_NULL;
            request_data <= 0;
            cursor <= ADDR_NULL;
            walk_index <= 0;
            target <= ADDR_NULL;
            new_node <= ADDR_NULL;
            append_node <= 0;
            operation_fault <= 0;
            node_valid <= 0;
            length <= 0;
            head <= ADDR_NULL;
            tail <= ADDR_NULL;
            data_out <= 0;
            pre_node_addr <= ADDR_NULL;
            next_node_addr <= ADDR_NULL;
            for (item = 0; item < MAX_NODE; item = item + 1) begin
                node_data[item] <= 0;
                node_next_node_addr[item] <= ADDR_NULL;
                node_pre_node_addr[item] <= ADDR_NULL;
            end
        end else begin
            case (state)
                IDLE: if (op_start) begin
                    request_op <= op;
                    request_addr <= addr_in;
                    request_data <= data_in;
                    new_node <= free_node;
                    operation_fault <= 0;
                    data_out <= 0;
                    pre_node_addr <= ADDR_NULL;
                    next_node_addr <= ADDR_NULL;
                    state <= DISPATCH;
                end
                DISPATCH: begin
                    case (request_op)
                        READ_ADDR: begin
                            if (request_addr < MAX_NODE && node_valid[request_addr]) begin
                                data_out <= node_data[request_addr];
                                pre_node_addr <= node_pre_node_addr[request_addr];
                                next_node_addr <= node_next_node_addr[request_addr];
                            end else begin
                                operation_fault <= 1;
                            end
                            state <= COMPLETE;
                        end
                        INSERT_ADDR: begin
                            if (full) begin
                                operation_fault <= 1;
                                state <= COMPLETE;
                            end else if (request_addr >= MAX_NODE) begin
                                append_node <= 1;
                                target <= head;
                                state <= INSERT_NODE;
                            end else if (node_valid[request_addr]) begin
                                append_node <= 0;
                                target <= request_addr;
                                state <= INSERT_NODE;
                            end else begin
                                operation_fault <= 1;
                                state <= COMPLETE;
                            end
                        end
                        INSERT_INDEX: begin
                            if (full) begin
                                operation_fault <= 1;
                                state <= COMPLETE;
                            end else if (request_addr >= length) begin
                                append_node <= 1;
                                target <= head;
                                state <= INSERT_NODE;
                            end else begin
                                append_node <= 0;
                                cursor <= head;
                                walk_index <= 0;
                                state <= WALK_INDEX;
                            end
                        end
                        DELETE_ADDR: begin
                            if (request_addr < MAX_NODE && node_valid[request_addr]) begin
                                target <= request_addr;
                                state <= DELETE_NODE;
                            end else begin
                                operation_fault <= 1;
                                state <= COMPLETE;
                            end
                        end
                        DELETE_INDEX: begin
                            if (request_addr >= length) begin
                                operation_fault <= 1;
                                state <= COMPLETE;
                            end else begin
                                cursor <= head;
                                walk_index <= 0;
                                state <= WALK_INDEX;
                            end
                        end
                        DELETE_VALUE: begin
                            if (empty) begin
                                operation_fault <= 1;
                                state <= COMPLETE;
                            end else begin
                                cursor <= head;
                                walk_index <= 0;
                                state <= WALK_VALUE;
                            end
                        end
                        default: begin
                            operation_fault <= 1;
                            state <= COMPLETE;
                        end
                    endcase
                end
                WALK_INDEX: begin
                    if (walk_index == request_addr) begin
                        target <= cursor;
                        state <= (request_op == INSERT_INDEX) ? INSERT_NODE : DELETE_NODE;
                    end else if (walk_index == length - 1) begin
                        operation_fault <= 1;
                        state <= COMPLETE;
                    end else begin
                        cursor <= node_next_node_addr[cursor];
                        walk_index <= walk_index + 1'b1;
                    end
                end
                WALK_VALUE: begin
                    if (node_data[cursor] == request_data) begin
                        target <= cursor;
                        state <= DELETE_NODE;
                    end else if (walk_index == length - 1) begin
                        // A ring has no NULL terminator; stop after one full lap.
                        operation_fault <= 1;
                        state <= COMPLETE;
                    end else begin
                        cursor <= node_next_node_addr[cursor];
                        walk_index <= walk_index + 1'b1;
                    end
                end
                INSERT_NODE: begin
                    node_data[new_node] <= request_data;
                    node_valid[new_node] <= 1;
                    if (empty) begin
                        node_next_node_addr[new_node] <= new_node;
                        node_pre_node_addr[new_node] <= new_node;
                        head <= new_node;
                        tail <= new_node;
                    end else begin
                        // Insert between target.prev and target, including the closing edge.
                        node_next_node_addr[new_node] <= target;
                        node_pre_node_addr[new_node] <= node_pre_node_addr[target];
                        node_next_node_addr[node_pre_node_addr[target]] <= new_node;
                        node_pre_node_addr[target] <= new_node;
                        if (append_node)
                            tail <= new_node;
                        else if (target == head)
                            head <= new_node;
                    end
                    length <= length + 1'b1;
                    state <= COMPLETE;
                end
                DELETE_NODE: begin
                    if (length == 1) begin
                        head <= ADDR_NULL;
                        tail <= ADDR_NULL;
                    end else begin
                        node_next_node_addr[node_pre_node_addr[target]] <= node_next_node_addr[target];
                        node_pre_node_addr[node_next_node_addr[target]] <= node_pre_node_addr[target];
                        if (target == head)
                            head <= node_next_node_addr[target];
                        if (target == tail)
                            tail <= node_pre_node_addr[target];
                    end
                    node_data[target] <= 0;
                    node_valid[target] <= 0;
                    node_next_node_addr[target] <= ADDR_NULL;
                    node_pre_node_addr[target] <= ADDR_NULL;
                    length <= length - 1'b1;
                    state <= COMPLETE;
                end
                COMPLETE: state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
