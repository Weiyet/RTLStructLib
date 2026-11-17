// Bounded binary heap. One outstanding command, one heap level per cycle.
module priority_queue #(
    parameter DEPTH = 16,
    parameter PRIORITY_WIDTH = 8,
    parameter DATA_WIDTH = 8,
    parameter MIN_FIRST = 1
) (
    input wire clk,
    input wire rst,
    input wire req_valid,
    output wire req_ready,
    input wire [1:0] req_op, // 0: push, 1: pop, 2: peek
    input wire [PRIORITY_WIDTH-1:0] req_priority,
    input wire [DATA_WIDTH-1:0] req_data,
    output wire rsp_valid,
    input wire rsp_ready,
    output reg rsp_error,
    output reg [PRIORITY_WIDTH-1:0] rsp_priority,
    output reg [DATA_WIDTH-1:0] rsp_data,
    output reg [((DEPTH < 2) ? 1 : $clog2(DEPTH+1))-1:0] count,
    output wire full,
    output wire empty
);
    localparam INDEX_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH);
    localparam IDLE = 2'd0, UP = 2'd1, DOWN = 2'd2, RESPONSE = 2'd3;
    reg [1:0] state;
    reg [INDEX_WIDTH-1:0] position;
    reg [PRIORITY_WIDTH-1:0] held_priority;
    reg [DATA_WIDTH-1:0] held_data;
    reg [PRIORITY_WIDTH-1:0] priorities [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] payloads [0:DEPTH-1];

    wire [INDEX_WIDTH-1:0] parent_index = (position - 1'b1) >> 1;
    // Keep the carry: leaves must not wrap around to low array addresses.
    wire [INDEX_WIDTH:0] left_index = {position, 1'b0} + 1'b1;
    wire [INDEX_WIDTH:0] right_index = left_index + 1'b1;
    reg [INDEX_WIDTH-1:0] child_index;
    reg child_valid;

    function automatic better;
        input [PRIORITY_WIDTH-1:0] a, b;
        begin
            better = MIN_FIRST ? (a < b) : (a > b);
        end
    endfunction

    always @* begin
        child_index = 0;
        child_valid = 0;
        if (left_index < count) begin
            child_index = left_index[INDEX_WIDTH-1:0];
            child_valid = 1;
            if (right_index < count) begin
                if (better(priorities[right_index], priorities[left_index]))
                    child_index = right_index[INDEX_WIDTH-1:0];
            end
        end
    end

    assign req_ready = !rst && state == IDLE;
    assign rsp_valid = !rst && state == RESPONSE;
    assign full = count == DEPTH;
    assign empty = count == 0;

    wire move_up = position != 0 && better(held_priority, priorities[parent_index]);
    wire move_down = child_valid && better(priorities[child_index], held_priority);
    reg [PRIORITY_WIDTH-1:0] write_priority;
    reg [DATA_WIDTH-1:0] write_data;
    always @* begin
        write_priority = held_priority;
        write_data = held_data;
        if (state == UP && move_up) begin
            write_priority = priorities[parent_index];
            write_data = payloads[parent_index];
        end else if (state == DOWN && move_down) begin
            write_priority = priorities[child_index];
            write_data = payloads[child_index];
        end
    end

    // One explicit synchronous write port per array, separate from resettable
    // control registers. Avoid inferring a write port for every FSM branch.
    always @(posedge clk) begin
        if (!rst && (state == UP || state == DOWN)) begin
            priorities[position] <= write_priority;
            payloads[position] <= write_data;
        end
    end

    generate
        if (DEPTH < 1 || PRIORITY_WIDTH < 1 || DATA_WIDTH < 1 ||
            (MIN_FIRST != 0 && MIN_FIRST != 1)) begin : invalid_parameters
            initial $fatal(1, "Priority Queue parameters must be positive; MIN_FIRST must be 0 or 1");
        end
    endgenerate

    // Storage has one write per cycle and asynchronous reads. Reset clears
    // metadata only; no claim of block-RAM inference is made for this variant.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
            position <= 0;
            held_priority <= 0;
            held_data <= 0;
            rsp_error <= 0;
            rsp_priority <= 0;
            rsp_data <= 0;
        end else begin
            case (state)
                IDLE: if (req_valid) begin
                    rsp_error <= 0;
                    rsp_priority <= 0;
                    rsp_data <= 0;
                    state <= RESPONSE;
                    case (req_op)
                        2'd0: if (full) begin
                            rsp_error <= 1;
                        end else begin
                            held_priority <= req_priority;
                            held_data <= req_data;
                            position <= count;
                            count <= count + 1'b1;
                            state <= UP;
                        end
                        2'd1, 2'd2: if (empty) begin
                            rsp_error <= 1;
                        end else begin
                            rsp_priority <= priorities[0];
                            rsp_data <= payloads[0];
                            if (req_op == 2'd1) begin
                                count <= count - 1'b1;
                                if (count > 1) begin
                                    held_priority <= priorities[count-1'b1];
                                    held_data <= payloads[count-1'b1];
                                    position <= 0;
                                    state <= DOWN;
                                end
                            end
                        end
                        default: rsp_error <= 1;
                    endcase
                end
                UP: begin
                    if (move_up) begin
                        position <= parent_index;
                    end else begin
                        state <= RESPONSE;
                    end
                end
                DOWN: begin
                    if (move_down) begin
                        position <= child_index;
                    end else begin
                        state <= RESPONSE;
                    end
                end
                RESPONSE: if (rsp_ready) state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
