module bitmap_free_list #(
    parameter integer CAPACITY = 16
)(
    input wire clk,
    input wire rst,
    input wire alloc_req,
    input wire free_req,
    input wire [(CAPACITY <= 1 ? 1 : $clog2(CAPACITY))-1:0] free_id,
    output reg alloc_valid,
    output reg alloc_error,
    output reg [(CAPACITY <= 1 ? 1 : $clog2(CAPACITY))-1:0] alloc_id,
    output reg free_valid,
    output reg free_error,
    output reg [(CAPACITY < 1 ? 1 : $clog2(CAPACITY+1))-1:0] free_count,
    output wire exhausted,
    output wire all_free
);
    localparam ID_WIDTH = (CAPACITY <= 1) ? 1 : $clog2(CAPACITY);
    localparam COUNT_WIDTH = (CAPACITY < 1) ? 1 : $clog2(CAPACITY+1);
    localparam BITMAP_WIDTH = (CAPACITY < 1) ? 1 : CAPACITY;
    reg [BITMAP_WIDTH-1:0] free_bitmap, next_bitmap;
    reg [COUNT_WIDTH-1:0] next_count;
    reg [ID_WIDTH-1:0] next_id;
    reg release_ok, allocate_ok;
    integer i;

    initial begin
        if (CAPACITY < 1)
            $fatal(1, "Bitmap Free List CAPACITY must be >= 1");
    end

    assign exhausted = (free_count == 0);
    assign all_free = (free_count == CAPACITY);

    always @* begin
        next_bitmap = free_bitmap;
        next_count = free_count;
        next_id = 0;
        release_ok = 0;
        allocate_ok = 0;
        // Validate against the state before this edge. Never index an invalid ID.
        if (free_req && ({1'b0, free_id} < CAPACITY)) begin
            if (!free_bitmap[free_id]) begin
                next_bitmap[free_id] = 1'b1;
                release_ok = 1;
                next_count = next_count + 1'b1;
            end
        end
        // Release-first forwarding allows reuse even when initially exhausted.
        for (i = 0; i < CAPACITY; i = i + 1) begin
            if (alloc_req && next_bitmap[i] && !allocate_ok) begin
                allocate_ok = 1;
                next_id = i[ID_WIDTH-1:0];
                next_bitmap[i] = 1'b0;
                next_count = next_count - 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            free_bitmap <= {BITMAP_WIDTH{1'b1}};
            free_count <= CAPACITY[COUNT_WIDTH-1:0];
            alloc_valid <= 0;
            alloc_error <= 0;
            alloc_id <= 0;
            free_valid <= 0;
            free_error <= 0;
        end else begin
            free_bitmap <= next_bitmap;
            free_count <= next_count;
            alloc_valid <= allocate_ok;
            alloc_error <= alloc_req && !allocate_ok;
            alloc_id <= next_id;
            free_valid <= release_ok;
            free_error <= free_req && !release_ok;
        end
    end
endmodule
