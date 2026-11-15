module table_top #(
    parameter TABLE_SIZE = 32,
    parameter DATA_WIDTH = 8,
    parameter INPUT_RATE = 2,
    parameter OUTPUT_RATE = 2
)(
    input wire clk,
    input wire rst,
    input wire [INPUT_RATE-1:0] wr_en,
    input wire rd_en,
    input wire [INPUT_RATE*((TABLE_SIZE < 2) ? 1 : $clog2(TABLE_SIZE))-1:0] index_wr,
    input wire [OUTPUT_RATE*((TABLE_SIZE < 2) ? 1 : $clog2(TABLE_SIZE))-1:0] index_rd,
    input wire [INPUT_RATE*DATA_WIDTH-1:0] data_wr,
    output reg [OUTPUT_RATE*DATA_WIDTH-1:0] data_rd
);
    localparam INDEX_WIDTH = (TABLE_SIZE < 2) ? 1 : $clog2(TABLE_SIZE);
    reg [DATA_WIDTH-1:0] data_stored [0:TABLE_SIZE-1];
    reg [OUTPUT_RATE*DATA_WIDTH-1:0] read_next;
    integer write_port, reset_index, read_port, forward_port;
    initial begin
        if (TABLE_SIZE < 1 || DATA_WIDTH < 1 || INPUT_RATE < 1 || OUTPUT_RATE < 1)
            $fatal(1, "Table parameters must be positive");
    end

    // Ascending port order gives the highest numbered enabled writer priority.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (reset_index = 0; reset_index < TABLE_SIZE; reset_index = reset_index + 1)
                data_stored[reset_index] <= 0;
        end else begin
            for (write_port = 0; write_port < INPUT_RATE; write_port = write_port + 1)
                if (wr_en[write_port] && index_wr[write_port*INDEX_WIDTH +: INDEX_WIDTH] < TABLE_SIZE)
                    data_stored[index_wr[write_port*INDEX_WIDTH +: INDEX_WIDTH]]
                        <= data_wr[write_port*DATA_WIDTH +: DATA_WIDTH];
        end
    end

    // Explicit write-through forwarding makes same-edge read/write deterministic.
    always @* begin
        read_next = 0;
        for (read_port = 0; read_port < OUTPUT_RATE; read_port = read_port + 1) begin
            if (index_rd[read_port*INDEX_WIDTH +: INDEX_WIDTH] < TABLE_SIZE) begin
                read_next[read_port*DATA_WIDTH +: DATA_WIDTH] =
                    data_stored[index_rd[read_port*INDEX_WIDTH +: INDEX_WIDTH]];
            end
            for (forward_port = 0; forward_port < INPUT_RATE; forward_port = forward_port + 1) begin
                if (wr_en[forward_port] &&
                    index_wr[forward_port*INDEX_WIDTH +: INDEX_WIDTH] < TABLE_SIZE &&
                    index_wr[forward_port*INDEX_WIDTH +: INDEX_WIDTH] == index_rd[read_port*INDEX_WIDTH +: INDEX_WIDTH])
                    read_next[read_port*DATA_WIDTH +: DATA_WIDTH] =
                        data_wr[forward_port*DATA_WIDTH +: DATA_WIDTH];
            end
        end
    end

    always @(posedge clk or posedge rst)
        if (rst) data_rd <= 0;
        else if (rd_en) data_rd <= read_next;
endmodule