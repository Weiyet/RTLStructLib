module lifo #(
    parameter DEPTH = 12,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] data_wr,
    input wire wr_en,
    output wire lifo_full,
    output reg [DATA_WIDTH-1:0] data_rd,
    input wire rd_en,
    output wire lifo_empty
);
    // Occupancy includes DEPTH itself, even for a power-of-two capacity.
    localparam CNTR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH + 1);
   
    reg [CNTR_WIDTH-1:0] pointer;
    reg [DATA_WIDTH-1:0] lifo_stored [DEPTH-1:0];
    wire wr_op;
    wire rd_op;
    wire bypass_op;
    
    integer i;
    
    assign wr_op = wr_en & !rd_en;
    assign rd_op = rd_en & !wr_en;
    assign bypass_op = wr_en & rd_en;

    // pointer logic 
    always @ (posedge clk, posedge rst) begin
        if(rst) begin
            pointer <= {CNTR_WIDTH{1'b0}};
        end else if(rd_op & !lifo_empty) begin
            pointer <= pointer - 1;
        end else if(wr_op & !lifo_full) begin
            pointer <= pointer + 1;
        end
    end
    
    // lifo memory
    always @ (posedge clk, posedge rst) begin
        if(rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                lifo_stored[i] <= {DATA_WIDTH{1'b0}};
        end else if (wr_op & !lifo_full) begin
            lifo_stored[pointer] <= data_wr;
        end 
    end

    // data_rd
    always @ (posedge clk, posedge rst) begin
        if(rst) begin
            data_rd <= {DATA_WIDTH{1'b0}};
        end else if (rd_op & !lifo_empty) begin
            data_rd <= lifo_stored[pointer-1];
        end else if (bypass_op) begin
            data_rd <= data_wr;
        end
    end

    // flag
    assign lifo_empty = pointer ==  {CNTR_WIDTH{1'b0}};
    assign lifo_full = pointer == DEPTH;
    
endmodule
