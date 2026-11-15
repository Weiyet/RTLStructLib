module hash_table #(
    parameter KEY_WIDTH = 32,
    parameter VALUE_WIDTH = 32,
    parameter TOTAL_INDEX = 8,
    parameter CHAINING_SIZE = 4,
    parameter COLLISION_METHOD = "MULTI_STAGE_CHAINING",
    parameter HASH_ALGORITHM = "MODULUS"
)(
    input wire clk,
    input wire rst,
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [VALUE_WIDTH-1:0] value_in,
    input wire [1:0] op_sel,
    input wire op_en,
    output reg [VALUE_WIDTH-1:0] value_out,
    output reg op_done,
    output reg op_error,
    output reg [((CHAINING_SIZE < 2) ? 1 : $clog2(CHAINING_SIZE+1))-1:0] collision_count
);
    localparam COUNT_WIDTH = (CHAINING_SIZE < 2) ? 1 : $clog2(CHAINING_SIZE+1);
    localparam INDEX_WIDTH = (TOTAL_INDEX < 2) ? 1 : $clog2(TOTAL_INDEX);
    localparam IDLE = 2'd0, SEARCH = 2'd1, COMPLETE = 2'd2;
    reg [1:0] state;
    reg [KEY_WIDTH-1:0] request_key;
    reg [VALUE_WIDTH-1:0] request_value;
    reg [1:0] request_op;
    reg [INDEX_WIDTH-1:0] bucket;
    reg [COUNT_WIDTH-1:0] cursor;
    reg [KEY_WIDTH*CHAINING_SIZE-1:0] keys [0:TOTAL_INDEX-1];
    reg [VALUE_WIDTH*CHAINING_SIZE-1:0] values [0:TOTAL_INDEX-1];
    reg [COUNT_WIDTH-1:0] counts [0:TOTAL_INDEX-1];
    wire at_end = cursor == counts[bucket];
    wire found = cursor < counts[bucket] && keys[bucket][cursor*KEY_WIDTH +: KEY_WIDTH] == request_key;
    wire append_entry = state == SEARCH && request_op == 0 && at_end && counts[bucket] < CHAINING_SIZE;
    wire write_entry = append_entry || (state == SEARCH && request_op == 0 && found);
    wire delete_entry = state == SEARCH && request_op == 1 && found;
    wire [INDEX_WIDTH-1:0] hash_index;

    generate
        if (TOTAL_INDEX == 1) begin : single_bucket
            assign hash_index = 0;
        end else if ((TOTAL_INDEX & (TOTAL_INDEX - 1)) == 0) begin : binary_buckets
            // Assignment truncates or zero-extends an unsigned key as needed.
            assign hash_index = key_in;
        end else begin : modulus_buckets
            // Process all key bits using an INDEX_WIDTH+1-bit remainder.
            // Before each stage remainder < TOTAL_INDEX, so one subtraction
            // suffices after shifting in the next bit. No general divider.
            localparam [INDEX_WIDTH:0] BUCKET_COUNT = TOTAL_INDEX;
            wire [INDEX_WIDTH:0] remainder [0:KEY_WIDTH];
            assign remainder[KEY_WIDTH] = 0;
            genvar key_bit;
            for (key_bit = 0; key_bit < KEY_WIDTH; key_bit = key_bit + 1) begin : stage
                wire [INDEX_WIDTH:0] shifted = {remainder[key_bit+1][INDEX_WIDTH-1:0], key_in[key_bit]};
                assign remainder[key_bit] = (shifted >= BUCKET_COUNT) ? shifted - BUCKET_COUNT : shifted;
            end
            assign hash_index = remainder[0][INDEX_WIDTH-1:0];
        end
    endgenerate

    // Static slices infer bounded per-slot enables instead of variable-width
    // barrel-shift write masks on entire packed buckets.
    genvar bucket_number;
    generate
        for (bucket_number = 0; bucket_number < TOTAL_INDEX; bucket_number = bucket_number + 1) begin : storage
            integer slot;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    keys[bucket_number] <= 0;
                    values[bucket_number] <= 0;
                    counts[bucket_number] <= 0;
                end else if (bucket == bucket_number) begin
                    if (append_entry) counts[bucket_number] <= counts[bucket_number] + 1'b1;
                    else if (delete_entry) counts[bucket_number] <= counts[bucket_number] - 1'b1;
                    for (slot = 0; slot < CHAINING_SIZE; slot = slot + 1) begin
                        if (write_entry && cursor == slot) begin
                            keys[bucket_number][slot*KEY_WIDTH +: KEY_WIDTH] <= request_key;
                            values[bucket_number][slot*VALUE_WIDTH +: VALUE_WIDTH] <= request_value;
                        end else if (delete_entry) begin
                            if (slot == counts[bucket_number] - 1) begin
                                keys[bucket_number][slot*KEY_WIDTH +: KEY_WIDTH] <= 0;
                                values[bucket_number][slot*VALUE_WIDTH +: VALUE_WIDTH] <= 0;
                            end else if (slot >= cursor && slot < counts[bucket_number] - 1) begin
                                if (slot < CHAINING_SIZE - 1) begin
                                    keys[bucket_number][slot*KEY_WIDTH +: KEY_WIDTH] <=
                                        keys[bucket_number][(slot+1)*KEY_WIDTH +: KEY_WIDTH];
                                    values[bucket_number][slot*VALUE_WIDTH +: VALUE_WIDTH] <=
                                        values[bucket_number][(slot+1)*VALUE_WIDTH +: VALUE_WIDTH];
                                end
                            end
                        end
                    end
                end
            end
        end
    endgenerate

    initial begin
        if (KEY_WIDTH < 1 || VALUE_WIDTH < 1 || TOTAL_INDEX < 1 || CHAINING_SIZE < 1)
            $fatal(1, "Hash Table parameters must be positive");
        if (HASH_ALGORITHM != "MODULUS" || COLLISION_METHOD != "MULTI_STAGE_CHAINING")
            $fatal(1, "Unsupported Hash Table algorithm or collision method");
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            request_key <= 0;
            request_value <= 0;
            request_op <= 0;
            bucket <= 0;
            cursor <= 0;
            value_out <= 0;
            collision_count <= 0;
            op_done <= 0;
            op_error <= 0;
        end else begin
            op_done <= 0;
            op_error <= 0;
            case (state)
                IDLE: begin
                    if (op_en) begin
                        request_key <= key_in;
                        request_value <= value_in;
                        request_op <= op_sel;
                        // Preserve all key bits and unsigned modulo semantics.
                        bucket <= hash_index;
                        cursor <= 0;
                        value_out <= 0;
                        collision_count <= 0;
                        state <= SEARCH;
                    end
                end
                SEARCH: begin
                    if (request_op == 2'b11) begin
                        op_done <= 1;
                        op_error <= 1;
                        state <= COMPLETE;
                    end else if (at_end) begin
                        // End-of-chain is checked before reading a candidate slot.
                        collision_count <= counts[bucket];
                        if (request_op == 0 && counts[bucket] < CHAINING_SIZE) begin
                            collision_count <= counts[bucket] + 1'b1;
                        end else begin
                            op_error <= 1;
                        end
                        op_done <= 1;
                        state <= COMPLETE;
                    end else if (found) begin
                        collision_count <= counts[bucket];
                        case (request_op)
                            0: begin end // storage updates without changing occupancy
                            1: begin
                                collision_count <= counts[bucket] - 1'b1;
                            end
                            2: value_out <= values[bucket][cursor*VALUE_WIDTH +: VALUE_WIDTH];
                            default: op_error <= 1;
                        endcase
                        op_done <= 1;
                        state <= COMPLETE;
                    end else begin
                        cursor <= cursor + 1'b1;
                    end
                end
                COMPLETE: state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
