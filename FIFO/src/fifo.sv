module fifo #(
    parameter DEPTH = 16,
    parameter DATA_WIDTH = 8,
    parameter ASYNC = 1,
    parameter RD_BUFFER = 1
)(
    input wire rd_clk,
    input wire wr_clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] data_wr,
    input wire wr_en,
    output wire fifo_full,
    output wire [DATA_WIDTH-1:0] data_rd,
    input wire rd_en,
    output wire fifo_empty
);
    localparam ADDR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam COUNT_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH + 1);

    initial begin
        if (DEPTH < 1 || DATA_WIDTH < 1 ||
            (ASYNC != 0 && ASYNC != 1) || (RD_BUFFER != 0 && RD_BUFFER != 1))
            $fatal(1, "FIFO parameters must be positive; ASYNC and RD_BUFFER must be 0 or 1");
        if (ASYNC && (DEPTH < 2 || (DEPTH & (DEPTH - 1)) != 0))
            $fatal(1, "Asynchronous FIFO DEPTH must be a power of two >= 2");
    end

    // Reset asserts asynchronously; each clock domain releases independently.
    (* ASYNC_REG = "TRUE" *) reg [1:0] wr_ready_pipe;
    (* ASYNC_REG = "TRUE" *) reg [1:0] rd_ready_pipe;
    always @(posedge wr_clk or posedge rst)
        if (rst) wr_ready_pipe <= 0;
        else wr_ready_pipe <= {wr_ready_pipe[0], 1'b1};
    always @(posedge rd_clk or posedge rst)
        if (rst) rd_ready_pipe <= 0;
        else rd_ready_pipe <= {rd_ready_pipe[0], 1'b1};
    wire wr_ready = wr_ready_pipe[1] && !rst;
    wire rd_ready = (ASYNC ? rd_ready_pipe[1] : wr_ready_pipe[1]) && !rst;

    wire [ADDR_WIDTH-1:0] wr_address, rd_address;
    wire push = wr_en && !fifo_full;
    wire pop = rd_en && !fifo_empty;
    reg [DATA_WIDTH-1:0] fifo_stored [0:DEPTH-1];
    // Reset invalidates pointers, not the memory; no uninitialized word is readable.
    always @(posedge wr_clk)
        if (push) fifo_stored[wr_address] <= data_wr;

    generate
        if (RD_BUFFER) begin : registered_read
            reg [DATA_WIDTH-1:0] read_data;
            always @(posedge rd_clk or posedge rst)
                if (rst) read_data <= 0;
                else if (!rd_ready) read_data <= 0;
                else if (pop) read_data <= fifo_stored[rd_address];
            assign data_rd = read_data;
        end else begin : combinational_read
            assign data_rd = pop ? fifo_stored[rd_address] : {DATA_WIDTH{1'b0}};
        end

        if (ASYNC) begin : async_fifo
            reg [PTR_WIDTH-1:0] wr_binary, rd_binary, wr_gray, rd_gray;
            (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rd_gray_meta, rd_gray_sync;
            (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wr_gray_meta, wr_gray_sync;
            reg full, empty;
            wire [PTR_WIDTH-1:0] wr_next = wr_binary + push;
            wire [PTR_WIDTH-1:0] rd_next = rd_binary + pop;
            wire [PTR_WIDTH-1:0] wr_gray_next = (wr_next >> 1) ^ wr_next;
            wire [PTR_WIDTH-1:0] rd_gray_next = (rd_next >> 1) ^ rd_next;
            // Invert the two highest Gray bits to compare a full ring apart.
            localparam [PTR_WIDTH-1:0] FULL_MASK = {2'b11, {(ADDR_WIDTH-1){1'b0}}};
            assign wr_address = wr_binary[ADDR_WIDTH-1:0];
            assign rd_address = rd_binary[ADDR_WIDTH-1:0];
            assign fifo_full = !wr_ready || full;
            assign fifo_empty = !rd_ready || empty;

            always @(posedge wr_clk or posedge rst) begin
                if (rst) begin
                    wr_binary <= 0;
                    wr_gray <= 0;
                    rd_gray_meta <= 0;
                    rd_gray_sync <= 0;
                    full <= 0;
                end else if (!wr_ready) begin
                    wr_binary <= 0;
                    wr_gray <= 0;
                    rd_gray_meta <= 0;
                    rd_gray_sync <= 0;
                    full <= 0;
                end else begin
                    rd_gray_meta <= rd_gray;
                    rd_gray_sync <= rd_gray_meta;
                    wr_binary <= wr_next;
                    wr_gray <= wr_gray_next;
                    full <= (wr_gray_next == (rd_gray_sync ^ FULL_MASK));
                end
            end
            always @(posedge rd_clk or posedge rst) begin
                if (rst) begin
                    rd_binary <= 0;
                    rd_gray <= 0;
                    wr_gray_meta <= 0;
                    wr_gray_sync <= 0;
                    empty <= 1;
                end else if (!rd_ready) begin
                    rd_binary <= 0;
                    rd_gray <= 0;
                    wr_gray_meta <= 0;
                    wr_gray_sync <= 0;
                    empty <= 1;
                end else begin
                    wr_gray_meta <= wr_gray;
                    wr_gray_sync <= wr_gray_meta;
                    rd_binary <= rd_next;
                    rd_gray <= rd_gray_next;
                    empty <= (rd_gray_next == wr_gray_sync);
                end
            end
        end else begin : sync_fifo
            reg [ADDR_WIDTH-1:0] wr_pointer, rd_pointer;
            reg [COUNT_WIDTH-1:0] count;
            assign wr_address = wr_pointer;
            assign rd_address = rd_pointer;
            assign fifo_full = !wr_ready || (count == DEPTH);
            assign fifo_empty = !rd_ready || (count == 0);
            // Contract: rd_clk and wr_clk must be the same clock in this mode.
            always @(posedge wr_clk or posedge rst) begin
                if (rst) begin
                    wr_pointer <= 0;
                    rd_pointer <= 0;
                    count <= 0;
                end else if (!wr_ready) begin
                    wr_pointer <= 0;
                    rd_pointer <= 0;
                    count <= 0;
                end else begin
                    if (push) wr_pointer <= (wr_pointer == DEPTH-1) ? 0 : wr_pointer + 1'b1;
                    if (pop) rd_pointer <= (rd_pointer == DEPTH-1) ? 0 : rd_pointer + 1'b1;
                    case ({push, pop})
                        2'b10: count <= count + 1'b1;
                        2'b01: count <= count - 1'b1;
                        default: count <= count;
                    endcase
                end
            end
        end
    endgenerate
endmodule