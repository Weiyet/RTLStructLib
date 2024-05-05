module fifo #(
    parameter DEPTH = 12,
    parameter DATA_WIDTH = 8,
    parameter ASYNC = 1
)(
    input wire rd_clk,
    input wire wr_clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] data_wr,
    input wire wr_en,
    output reg fifo_full,
    output wire [DATA_WIDTH-1:0] data_rd,
    input wire rd_en,
    output wire fifo_empty
);
    localparam CNTR_WIDTH = clogb2(DEPTH);
   
    reg [CNTR_WIDTH-1:0] rd_gray_pointer, rd_binary_pointer;
    wire [CNTR_WIDTH-1:0] rd_binary_pointer_next;
    reg [CNTR_WIDTH-1:0] wr_gray_pointer, wr_binary_pointer;
    wire [CNTR_WIDTH-1:0] wr_binary_pointer_next;
    reg [DATA_WIDTH-1:0] fifo_stored [DEPTH-1:0];
    reg [CNTR_WIDTH-1:0] rd_gray_pointer_sync[1:0];
    reg [CNTR_WIDTH-1:0] wr_gray_pointer_sync[1:0];
    wire rdptr_eq_next_wrptr;
    
    generate //: POINTER_SYNCHRONIZER
        if (ASYNC == 1) begin
            always @ (posedge rd_clk, posedge rst) begin
                if(rst) begin
                    {wr_gray_pointer_sync[1], wr_gray_pointer_sync[0]} <= {(2*CNTR_WIDTH){1'b0}};
                end else begin
                    {wr_gray_pointer_sync[1], wr_gray_pointer_sync[0]} <= {wr_gray_pointer_sync[0], wr_gray_pointer};
                end
            end

            always @ (posedge wr_clk, posedge rst) begin
                if(rst) begin
                    {rd_gray_pointer_sync[1], rd_gray_pointer_sync[0]} <= {(2*CNTR_WIDTH){1'b0}};
                end else begin
                    {rd_gray_pointer_sync[1], rd_gray_pointer_sync[0]} <= {rd_gray_pointer_sync[0], rd_gray_pointer};
                end
            end
        end 
    endgenerate

    // data_wr, wr_binary_pointer, wr_gray_pointer 
    assign wr_binary_pointer_next = (wr_binary_pointer == DEPTH-1) ? {CNTR_WIDTH{1'b0}} : wr_binary_pointer + 1;
    
    integer i;
    
    always @ (posedge wr_clk, posedge rst) begin
        if(rst) begin
            wr_binary_pointer <= {CNTR_WIDTH{1'b0}};
        end else if((wr_en & !rdptr_eq_next_wrptr) | (fifo_full & !rdptr_eq_next_wrptr)) begin
        // 1. When next write pointer == read pointer AND wr_en, it means last entry of FIFO is being filled, do not update pointer, else update pointer.
        // 2. Update when fifo_full flag is cleared.
            wr_binary_pointer <= wr_binary_pointer_next;
        end
    end
    
    always @ (posedge wr_clk, posedge rst) begin
        if(rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                fifo_stored[i] <= {DATA_WIDTH{1'b0}};
        end else if (wr_en & !fifo_full) begin
            fifo_stored[wr_binary_pointer] <= data_wr;
        end
    end

    generate
        if(ASYNC == 1) begin
            always @ (posedge wr_clk, posedge rst) begin
                if(rst) begin
                    wr_gray_pointer   <= {CNTR_WIDTH{1'b0}};
                end else if ((wr_en & !rdptr_eq_next_wrptr) | (fifo_full & !rdptr_eq_next_wrptr)) begin
                // 1. When next write pointer == read pointer AND wr_en, it means last entry of FIFO is being filled, do not update pointer, else update pointer.
                // 2. Update when fifo_full flag is cleared.
                    wr_gray_pointer   <= bin_to_gray(wr_binary_pointer_next); 
                end
            end
        end
    endgenerate


    // data_rd, rd_binary_pointer, rd_gray_pointer 
    assign rd_binary_pointer_next = (rd_binary_pointer == DEPTH-1) ? {CNTR_WIDTH{1'b0}} : rd_binary_pointer + 1;
    
    always @ (posedge rd_clk, posedge rst) begin
        if(rst) begin
            rd_binary_pointer <= {CNTR_WIDTH{1'b0}};
        end else if (rd_en & !fifo_empty) begin
            rd_binary_pointer <= rd_binary_pointer_next;
        end
    end
    
    assign data_rd = (rd_en & !fifo_empty) ? fifo_stored[rd_binary_pointer] : {DATA_WIDTH{1'b0}}; 

    generate
        if(ASYNC == 1) begin
            always @ (posedge rd_clk, posedge rst) begin
                if(rst) begin
                    rd_gray_pointer   <= {CNTR_WIDTH{1'b0}};
                end else if(rd_en & !fifo_empty) begin
                    rd_gray_pointer   <= bin_to_gray(rd_binary_pointer_next);
                end
            end
        end
    endgenerate

    // flag
    generate 
        if (ASYNC == 1) begin
            assign rdptr_eq_next_wrptr = (rd_gray_pointer_sync[1] == bin_to_gray(wr_binary_pointer_next));
            assign fifo_empty = wr_gray_pointer_sync[1] == bin_to_gray(rd_binary_pointer);
            //assign fifo_full = rd_gray_pointer_sync[1] == bin_to_gray(wr_binary_pointer_next);
        end else begin
            assign rdptr_eq_next_wrptr = (rd_binary_pointer == wr_binary_pointer_next);
            assign fifo_empty = wr_binary_pointer == rd_binary_pointer;
            //assign fifo_full = rd_binary_pointer == wr_binary_pointer_next;
        end
    endgenerate
    
    always@(posedge wr_clk, posedge rst) begin
        if(rst) begin
            fifo_full <= 1'b0;
        end else if(wr_en & rdptr_eq_next_wrptr) begin
        // When next write pointer == read pointer AND wr_en, it means last entry of FIFO is being filled, do not update pointer,
            fifo_full <= 1'b1;
        end else if(!rdptr_eq_next_wrptr) begin
        // Deassert when any read operation is completed: write pointer != read pointer
            fifo_full <= 1'b0;
        end
    end
    
    function integer clogb2;
        input integer value;
        value = value - (value > 1);
        for(clogb2=0; value>0; value = value>>1)
             clogb2 = clogb2 + 1;
    endfunction

    function [CNTR_WIDTH-1:0] bin_to_gray;
        input [CNTR_WIDTH-1:0] bin;
        bin_to_gray = bin[CNTR_WIDTH-1:0] ^ (bin[CNTR_WIDTH-1:0] >> 1);   
    endfunction

endmodule
