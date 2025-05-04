`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 18/04/2025 01:15 AM
// Last Update: 05/05/2025 06:07 PM
// Module Name: Hash Table
// Author: https://www.linkedin.com/in/wei-yet-ng-065485119/
// Description: 
// Additional Comments: .
// 
//////////////////////////////////////////////////////////////////////////////////

module hash_table #(
    parameter KEY_WIDTH = 32,
    parameter VALUE_WIDTH = 32,
    parameter TOTAL_INDEX = 8,  // Total index of the hash table
    parameter CHAINING_SIZE = 4, // Number of chains for SINGLE_CYCLE_CHAINING and MULTI_STAGE_CHAINING only
    parameter COLLISION_METHOD = "MULTI_STAGE_CHAINING",  // "MULTI_STAGE_CHAINING", "LINEAR_PROBING" 
    parameter HASH_ALGORITHM = "MODULUS"  // "MODULUS", "SHA1", "FNV1A"
)(

    input wire clk,
    input wire rst,
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [VALUE_WIDTH-1:0] value_in,
    input wire [1:0] op_sel, // 00: Insert, 01: Delete, 10: Search
    input wire op_en,
    output reg [VALUE_WIDTH-1:0] value_out,
    output reg op_done,
    output reg op_error, // FULL when insert FAIL, KEY_NOT_FOUND when delete or search FAIL
    output reg [$clog2(CHAINING_SIZE-1)-1:0] collision_count 
);

    parameter CHAINING_SIZE_WIDTH = $clog2(CHAINING_SIZE+1); 
    parameter INDEX_WIDTH = $clog2(TOTAL_INDEX);
    
    reg [2:0] current_state;
    //reg [2:0] next_state;
    reg [KEY_WIDTH*CHAINING_SIZE-1:0] hash_key_stored [0:TOTAL_INDEX-1];
    reg [VALUE_WIDTH*CHAINING_SIZE-1:0] hash_value_stored [0:TOTAL_INDEX-1];
    reg [CHAINING_SIZE_WIDTH-1:0] hash_chain_count [0:TOTAL_INDEX-1]; // for collision count
    reg [CHAINING_SIZE_WIDTH-1:0] search_ptr; // for searching the key in the chain
    reg [CHAINING_SIZE_WIDTH-1:0] next_search_ptr; // for searching the key in the chain
    integer i;
    
    localparam  IDLE       = 3'b000;
    localparam  SEARCH_KEY = 3'b001;
    localparam  INSERT     = 3'b010;
    localparam  DELETE     = 3'b011;
    localparam  READ       = 3'b100;
    localparam  OP_DONE    = 3'b101;

    // Hash function selector
    function integer get_hash_index;
        input integer key;
        reg [31:0] hash_value;
        begin
            if (HASH_ALGORITHM == "MODULUS")
                hash_value = key % TOTAL_INDEX;
            else // for future implentation of other hash algorithm
                hash_value = key;
                
            get_hash_index = hash_value[INDEX_WIDTH-1:0];
        end
    endfunction

    // Collision resolution method
    always @ (posedge clk, posedge rst) begin
        if(rst) begin
            current_state <= IDLE;
            search_ptr <= 0;
            value_out <= 0;
            collision_count <= 0;
            op_done <= 0;
            op_error <= 0;
            for (i = 0; i < TOTAL_INDEX; i++) begin
               hash_key_stored[i] <= 0;
               hash_value_stored[i] <= 0;
               hash_chain_count[i] <= 0;
            end
        end else begin               
            case(current_state)
                IDLE: begin
                    if (op_en) begin
                        case (op_sel)
                            2'b00: current_state <= SEARCH_KEY; //INSERT 
                            2'b01: current_state <= SEARCH_KEY; //DELETE
                            2'b10: current_state <= SEARCH_KEY; //SEARCH
                            default: current_state <= IDLE;
                        endcase
                    end else begin
                        current_state <= IDLE;
                    end
                    search_ptr <= 0;
                    value_out <= 0;
                    collision_count <= 0;
                    op_done <= 0;
                    op_error <= 0;
                end
    
                INSERT: begin
                        // Insert logic here
                        hash_key_stored[get_hash_index(key_in)][search_ptr*KEY_WIDTH +: KEY_WIDTH] <= key_in;
                        hash_value_stored[get_hash_index(key_in)][search_ptr*VALUE_WIDTH +: VALUE_WIDTH] <= value_in;
                        hash_chain_count[get_hash_index(key_in)] <= hash_chain_count[get_hash_index(key_in)] + 1;
                        op_done <= 1;
                        op_error <= 0; // No error
                        current_state <= OP_DONE;
                end
                
                DELETE: begin
                       // Delete logic here
                       // Remove key and value from hash table
                       // Shift the rest of the chain
                       // use for loop instead                    
                       for (i = 0; i < CHAINING_SIZE - 1; i++) begin
                          if (i >= search_ptr) begin
                             hash_key_stored[get_hash_index(key_in)][(i*KEY_WIDTH) +: KEY_WIDTH] <= hash_key_stored[get_hash_index(key_in)][((i+1)*KEY_WIDTH) +: KEY_WIDTH];
                             hash_value_stored[get_hash_index(key_in)][(i*VALUE_WIDTH) +: VALUE_WIDTH] <= hash_value_stored[get_hash_index(key_in)][((i+1)*VALUE_WIDTH) +: VALUE_WIDTH];
                          end else begin
                             hash_key_stored[get_hash_index(key_in)][(i*KEY_WIDTH) +: KEY_WIDTH] <= {KEY_WIDTH{1'b0}};
                             hash_value_stored[get_hash_index(key_in)][(i*VALUE_WIDTH) +: VALUE_WIDTH] <= {VALUE_WIDTH{1'b0}};
                          end                              
                       end
                       hash_chain_count[get_hash_index(key_in)] <= hash_chain_count[get_hash_index(key_in)] - 1;
                       current_state <= OP_DONE;
                       op_done <= 1;
                       op_error <= 0; // No error
                end
    
                READ: begin
                    // Search logic here
                    // Return the value associated with the key
                    value_out <= hash_value_stored[get_hash_index(key_in)] >> search_ptr*VALUE_WIDTH;
                    collision_count <= hash_chain_count[get_hash_index(key_in)];
                    current_state <= OP_DONE;
                    op_done <= 1;
                    op_error <= 0; // No error
                end
                
                SEARCH_KEY: begin
                     if (hash_chain_count[get_hash_index(key_in)] == 0) begin
                        if(op_sel == 2'b00) begin
                          current_state <= INSERT;
                        end else begin
                            collision_count <= 0;
                            op_done <= 1;
                            op_error <= 1; // KEY_NOT_FOUND error
                            current_state <= OP_DONE;
                        end
                    end else if(key_in == hash_key_stored[get_hash_index(key_in)][search_ptr*KEY_WIDTH +: KEY_WIDTH]) begin
                        if(op_sel == 2'b00) begin
                            current_state <= INSERT;
                        end else if (op_sel == 2'b01) begin
                            current_state <= DELETE;
                        end else if (op_sel == 2'b10) begin
                            current_state <= READ;
                        end
                    end else if (search_ptr == hash_chain_count[get_hash_index(key_in)]) begin
                        if(op_sel == 2'b00 & (hash_chain_count[get_hash_index(key_in)] < CHAINING_SIZE)) begin
                            current_state <= INSERT;
                        end else begin
                            collision_count <= CHAINING_SIZE;
                            op_done <= 1;
                            op_error <= 1; // KEY_NOT_FOUND error
                            current_state <= OP_DONE;
                        end
                    end else begin
                        current_state <= SEARCH_KEY;
                        search_ptr <= search_ptr + 1;
                    end
                end
                
                OP_DONE: begin
                    current_state <= IDLE;
                    op_done <= 0;
                    op_error <= 0;
                end
    
                default: current_state <= IDLE;
            endcase
        end
    end

endmodule
