`timescale 1ns / 1ps
// Fixed node pool: next pointers only; predecessor lookup visits one node per clock.
// Operation codes and port order follow the original singly linked-list interface.
module singly_linked_list #(
    parameter DATA_WIDTH = 8,
    parameter MAX_NODE = 8,
    localparam ADDR_WIDTH = (MAX_NODE > 0) ? $clog2(MAX_NODE+1) : 1
)(
    input wire rst, clk,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [ADDR_WIDTH-1:0] addr_in,
    input wire [2:0] op,
    input wire op_start,
    output wire op_done,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [ADDR_WIDTH-1:0] next_node_addr,
    output reg [ADDR_WIDTH-1:0] length, head, tail,
    output wire full, empty, fault
);
    localparam [ADDR_WIDTH-1:0] ADDR_NULL = MAX_NODE;
    localparam READ_ADDR = 3'd0, INSERT_ADDR = 3'd1, DELETE_VALUE = 3'd2,
               DELETE_ADDR = 3'd3, INSERT_INDEX = 3'd5, DELETE_INDEX = 3'd7;
    localparam IDLE = 3'd0, DISPATCH = 3'd1, WALK = 3'd2,
               INSERT_NODE = 3'd3, DELETE_NODE = 3'd4, COMPLETE = 3'd5;
    reg [DATA_WIDTH-1:0] node_data [0:MAX_NODE-1];
    reg [ADDR_WIDTH-1:0] node_next_node_addr [0:MAX_NODE-1];
    reg [MAX_NODE-1:0] node_valid;
    reg [2:0] state, request_op;
    reg [DATA_WIDTH-1:0] request_data;
    reg [ADDR_WIDTH-1:0] request_addr, cursor, predecessor, walk_index, target, new_node;
    reg operation_fault;
    reg [ADDR_WIDTH-1:0] free_node;
    integer candidate;

    // A fixed-width priority encoder; no 32-bit integer validity-mask truncation.
    always @(*) begin
        free_node = ADDR_NULL;
        for (candidate = MAX_NODE-1; candidate >= 0; candidate = candidate - 1)
            if (!node_valid[candidate])
                free_node = candidate;
    end

    wire walk_match = (request_op == DELETE_VALUE) ? node_data[cursor] == request_data :
                      (request_op == INSERT_INDEX || request_op == DELETE_INDEX) ?
                          walk_index == request_addr : cursor == request_addr;
    assign op_done = !rst && state == COMPLETE;
    assign fault = op_done && operation_fault;
    assign full = (length == MAX_NODE);
    assign empty = (length == 0);

    generate
        if (DATA_WIDTH < 1 || MAX_NODE < 1) begin : gen_invalid_parameters
            initial $fatal(1, "Invalid singly_linked_list parameters");
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
            predecessor <= ADDR_NULL;
            walk_index <= 0;
            target <= ADDR_NULL;
            new_node <= ADDR_NULL;
            operation_fault <= 0;
            node_valid <= 0;
            length <= 0;
            head <= ADDR_NULL;
            tail <= ADDR_NULL;
            data_out <= 0;
            next_node_addr <= ADDR_NULL;
            for (item = 0; item < MAX_NODE; item = item + 1) begin
                node_data[item] <= 0;
                node_next_node_addr[item] <= ADDR_NULL;
            end
        end else begin
            case (state)
                IDLE: if (op_start) begin
                    request_op <= op;
                    request_addr <= addr_in;
                    request_data <= data_in;
                    new_node <= free_node;
                    operation_fault <= 0;
                    state <= DISPATCH;
                end
                DISPATCH: begin
                    case (request_op)
                        READ_ADDR: begin
                            if (request_addr < MAX_NODE && node_valid[request_addr]) begin
                                data_out <= node_data[request_addr];
                                next_node_addr <= node_next_node_addr[request_addr];
                            end else begin
                                operation_fault <= 1;
                            end
                            state <= COMPLETE;
                        end
                        INSERT_ADDR, INSERT_INDEX: begin
                            if (full) begin
                                operation_fault <= 1;
                                state <= COMPLETE;
                            end else if ((request_op == INSERT_ADDR && request_addr >= MAX_NODE) ||
                                         (request_op == INSERT_INDEX && request_addr >= length)) begin
                                predecessor <= tail;
                                target <= ADDR_NULL;
                                state <= INSERT_NODE;
                            end else if (request_op == INSERT_ADDR && !node_valid[request_addr]) begin
                                operation_fault <= 1;
                                state <= COMPLETE;
                            end else begin
                                cursor <= head;
                                predecessor <= ADDR_NULL;
                                walk_index <= 0;
                                state <= WALK;
                            end
                        end
                        DELETE_ADDR, DELETE_INDEX, DELETE_VALUE: begin
                            if (empty ||
                                (request_op == DELETE_ADDR &&
                                 (request_addr >= MAX_NODE || !node_valid[request_addr])) ||
                                (request_op == DELETE_INDEX && request_addr >= length)) begin
                                operation_fault <= 1;
                                state <= COMPLETE;
                            end else begin
                                cursor <= head;
                                predecessor <= ADDR_NULL;
                                walk_index <= 0;
                                state <= WALK;
                            end
                        end
                        default: begin
                            operation_fault <= 1;
                            state <= COMPLETE;
                        end
                    endcase
                end
                WALK: begin
                    if (cursor == ADDR_NULL || walk_index >= length) begin
                        operation_fault <= 1;
                        state <= COMPLETE;
                    end else if (walk_match) begin
                        target <= cursor;
                        state <= (request_op == INSERT_ADDR || request_op == INSERT_INDEX) ?
                                 INSERT_NODE : DELETE_NODE;
                    end else if (walk_index == length - 1'b1) begin
                        operation_fault <= 1;
                        state <= COMPLETE;
                    end else begin
                        predecessor <= cursor;
                        cursor <= node_next_node_addr[cursor];
                        walk_index <= walk_index + 1'b1;
                    end
                end
                INSERT_NODE: begin
                    node_data[new_node] <= request_data;
                    node_valid[new_node] <= 1;
                    node_next_node_addr[new_node] <= target;
                    if (predecessor == ADDR_NULL)
                        head <= new_node;
                    else
                        node_next_node_addr[predecessor] <= new_node;
                    if (target == ADDR_NULL)
                        tail <= new_node;
                    length <= length + 1'b1;
                    state <= COMPLETE;
                end
                DELETE_NODE: begin
                    if (predecessor == ADDR_NULL)
                        head <= node_next_node_addr[target];
                    else
                        node_next_node_addr[predecessor] <= node_next_node_addr[target];
                    if (target == tail)
                        tail <= predecessor;
                    node_data[target] <= 0;
                    node_valid[target] <= 0;
                    node_next_node_addr[target] <= ADDR_NULL;
                    length <= length - 1'b1;
                    state <= COMPLETE;
                end
                COMPLETE: state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
