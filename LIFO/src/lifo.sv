module lifo #(
    parameter DEPTH = 12,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] data_wr,
    input wire wr_en,
    output reg lifo_full,
    output reg [DATA_WIDTH-1:0] data_rd,
    input wire rd_en,
    output wire lifo_empty
);
    localparam CNTR_WIDTH = $clog2(DEPTH);
   
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
    always @ (posedge clk, posedge rst) begin
        if(rst) begin
            lifo_full <= 1'b0;
        end else if(rd_op) begin
            lifo_full <= 1'b0;
        end else if(pointer == (DEPTH-1) & wr_op) begin
            lifo_full <= 1'b1;
        end
    end
    
    // assign lifo_full = pointer == (DEPTH); 
    // can use this as flag and modify read cond when lifo is full
    // if lifo_full : data_rd <= (lifo_stored[pointer-1]) else data_rd <= lifo_stored[pointer]
    //              : pointer <= pointer - 2             else pointer <= pointer <= pointer -1
    
endmodule
