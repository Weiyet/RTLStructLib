`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 18/04/2025 1:15 AM
// Last Update: 19/04/2025 12:15 AM
// Module Name: Hash Table
// Description: Support coliision method of Chaining and Hash Algorithm FNV1A and SHA1  
// Additional Comments: .
// 
//////////////////////////////////////////////////////////////////////////////////

module hash_table #(
    parameter KEY_WIDTH = 32,
    parameter VALUE_WIDTH = 32,
    parameter TOTAL_ENTRY = 64,  // Total index of the hash table
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
    output reg [$clog2(CHAINING_SIZE)-1:0] collision_count 
);

    parameter CHAINING_SIZE_WIDTH = $clog2(CHAINING_SIZE); 
    parameter INDEX_WIDTH = $clog2(TOTAL_ENTRY);
    
    reg [1:0] current_state;
    reg [1:0] next_state;
    reg [KEY_WIDTH*CHAINING_SIZE-1:0] hash_key_stored [0:INDEX_WIDTH-1];
    reg [VALUE_WIDTH*CHAINING_SIZE-1:0] hash_value_stored [0:INDEX_WIDTH-1];
    reg [CHAINING_SIZE_WIDTH-1:0] hash_chain_count [0:INDEX_WIDTH-1]; // for collision count
    reg [CHAINING_SIZE_WIDTH-1:0] search_ptr; // for searching the key in the chain
    integer i;
    localparam  IDLE       = 2'b00;
    localparam  INSERT     = 2'b01;
    localparam  SEARCH_KEY = 2'b10;

    // Hash function selector
    function [INDEX_WIDTH-1:0] get_hash_index;
        input [KEY_WIDTH-1:0] key;
        reg [31:0] hash_value;
        begin
            if (HASH_ALGORITHM == "MODULUS")
                hash_value = key % TOTAL_ENTRY;
            else // for future implentation of other hash algorithm
                hash_value = key;
                
            get_hash_index = hash_value[INDEX_WIDTH-1:0];
        end
    endfunction

    // Collision resolution method
    always @ (posedge clk, posedge rst) begin
        if(rst)
            current_state <= IDLE;
        else  
            current_state <= next_state;
    end

    always @ (*) begin
        case(current_state)
            IDLE: begin
                if (op_en) begin
                    case (op_sel)
                        2'b00: next_state <= INSERT;
                        2'b01: next_state <= SEARCH_KEY; //DELETE
                        2'b10: next_state <= SEARCH_KEY; //SEARCH
                        default: next_state <= IDLE;
                    endcase
                end else begin
                    next_state <= IDLE;
                end
                search_ptr <= 0;
                op_done <= 0;
                op_error <= 0;
                collision_count <= 0;
            end

            INSERT: begin
                if (collision_count[get_hash_index(key_in)] < CHAINING_SIZE) begin
                    // Insert logic here
                    hash_key_stored[get_hash_index(key_in)][hash_chain_count[get_hash_index(key_in)]*KEY_WIDTH +: KEY_WIDTH] <= key_in;
                    hash_value_stored[get_hash_index(key_in)][hash_chain_count[get_hash_index(key_in)]*VALUE_WIDTH +: VALUE_WIDTH] <= value_in;
                    hash_chain_count[get_hash_index(key_in)] <= hash_chain_count[get_hash_index(key_in)] + 1;
                    next_state <= IDLE;
                end else begin
                    op_done <= 1;
                    op_error <= 1; // FULL error
                    next_state <= IDLE;
                end
            end

            SEARCH_KEY: begin
                if(key_in == hash_key_stored[get_hash_index(key_in)][search_ptr*KEY_WIDTH +: KEY_WIDTH]) begin
                    if(op_sel == 2'b01) begin
                        // Delete logic here
                        // Remove key and value from hash table
                        // Shift the rest of the chain
                        // use for loop instead                    
                        hash_key_stored[get_hash_index(key_in)] <= ((hash_key_stored[get_hash_index(key_in)]>>((search_ptr + 1)*KEY_WIDTH)) << ((search_ptr+1)*KEY_WIDTH)) ^ (hash_key_stored[get_hash_index(key_in)] & ({(KEY_WIDTH*CHAINING_SIZE){1'b1}}>>((search_ptr + 1)*KEY_WIDTH)));
                        hash_value_stored[get_hash_index(key_in)]<= ((hash_value_stored[get_hash_index(key_in)]>>((search_ptr + 1)*VALUE_WIDTH)) << ((search_ptr+1)*VALUE_WIDTH)) ^ (hash_value_stored[get_hash_index(key_in)] & ({(VALUE_WIDTH*CHAINING_SIZE){1'b1} }>>((search_ptr + 1)*VALUE_WIDTH)));
                        hash_chain_count[get_hash_index(key_in)] <= hash_chain_count[get_hash_index(key_in)] - 1;
                        op_done <= 1;
                        op_error <= 0; // No error
                    end else if (op_sel == 2'b10) begin
                        // Search logic here
                        // Return the value associated with the key
                        value_out <= hash_value_stored[get_hash_index(key_in)] >> search_ptr*VALUE_WIDTH;
                        collision_count <= hash_chain_count[get_hash_index(key_in)];
                        op_done <= 1;
                        op_error <= 0; // No error
                    end
                end else if (search_ptr >= (hash_chain_count[get_hash_index(key_in)]-1)) begin
                    collision_count <= CHAINING_SIZE;
                    op_done <= 1;
                    op_error <= 1; // KEY_NOT_FOUND error
                    next_state <= IDLE;
                end else begin
                    search_ptr <= search_ptr + 1;
                end
            end

            default: next_state <= IDLE;
        endcase
    end

endmodule
