module hash_table #(
    parameter KEY_WIDTH = 32,
    parameter VALUE_WIDTH = 32,
    parameter TABLE_SIZE = 64,  // Must be power of 2
    parameter COLLISION_METHOD = "LINEAR_PROBE",  // "LINEAR_PROBE" or "CHAINING"
    parameter HASH_ALGORITHM = "FNV1A"  // "FNV1A" or "SHA1"
)(
    input wire clk,
    input wire rst,
    
    // Write interface
    input wire wr_en,
    input wire [KEY_WIDTH-1:0] wr_key,
    input wire [VALUE_WIDTH-1:0] wr_value,
    output reg wr_done,
    output reg wr_collision,
    
    // Read interface
    input wire rd_en,
    input wire [KEY_WIDTH-1:0] rd_key,
    output reg [VALUE_WIDTH-1:0] rd_value,
    output reg rd_valid,
    output reg rd_miss,
    
    // Deletion interface
    input wire del_en,
    input wire [KEY_WIDTH-1:0] del_key,
    output reg del_done,
    
    // Status
    output wire [15:0] filled_entries,
    output wire [15:0] collision_count
);

    // Hash table parameters
    localparam INDEX_WIDTH = $clog2(TABLE_SIZE);
    
    // Hash table storage
    reg [KEY_WIDTH-1:0] keys [TABLE_SIZE-1:0];
    reg [VALUE_WIDTH-1:0] values [TABLE_SIZE-1:0];
    reg valid [TABLE_SIZE-1:0];  // Entry is valid
    reg tomb [TABLE_SIZE-1:0];   // Tombstone marker for deleted entries
    
    // Counters for statistics
    reg [15:0] entry_count;
    reg [15:0] collisions;
    
    assign filled_entries = entry_count;
    assign collision_count = collisions;
    
    // FNV-1a hash function
    function [31:0] fnv1a_hash;
        input [KEY_WIDTH-1:0] key;
        reg [31:0] hash;
        integer i;
        begin
            hash = 32'h811c9dc5; // FNV offset basis
            for (i = 0; i < KEY_WIDTH; i = i + 8) begin
                hash = hash ^ key[i +: 8];
                hash = hash * 32'h01000193; // FNV prime
            end
            fnv1a_hash = hash;
        end
    endfunction
    
    // Simplified SHA-1 hash function for hardware
    // This is a hardware-friendly approximation of SHA-1's mixing function
    function [31:0] sha1_hash;
        input [KEY_WIDTH-1:0] key;
        reg [31:0] h0, h1, h2, h3, h4;
        reg [31:0] a, b, c, d, e, f, k, temp;
        integer i;
        begin
            // Initialize hash values
            h0 = 32'h67452301;
            h1 = 32'hEFCDAB89;
            h2 = 32'h98BADCFE;
            h3 = 32'h10325476;
            h4 = 32'hC3D2E1F0;
            
            // Process key in blocks - simplified for hardware implementation
            a = h0; b = h1; c = h2; d = h3; e = h4;
            
            // Process words - we'll do just a few rounds as a simplification
            for (i = 0; i < 4; i = i + 1) begin
                if (i < KEY_WIDTH/32) begin
                    // Extract 32-bit word from key
                    temp = (i < KEY_WIDTH/32) ? key[i*32 +: 32] : 32'h0;
                    
                    // Different operations for different rounds
                    case (i % 4)
                        0: begin 
                            f = (b & c) | ((~b) & d);
                            k = 32'h5A827999;
                        end
                        1: begin 
                            f = b ^ c ^ d;
                            k = 32'h6ED9EBA1;
                        end
                        2: begin 
                            f = (b & c) | (b & d) | (c & d);
                            k = 32'h8F1BBCDC;
                        end
                        3: begin 
                            f = b ^ c ^ d;
                            k = 32'hCA62C1D6;
                        end
                    endcase
                    
                    // SHA-1 main calculation - simplified
                    temp = ((a << 5) | (a >> 27)) + f + e + k + temp;
                    e = d;
                    d = c;
                    c = (b << 30) | (b >> 2);
                    b = a;
                    a = temp;
                end
            end
            
            // Final hash result
            h0 = h0 + a;
            h1 = h1 + b;
            h2 = h2 + c;
            h3 = h3 + d;
            h4 = h4 + e;
            
            // Return h0 as the hash value
            sha1_hash = h0 ^ h1;
        end
    endfunction
    
    // Hash function selector
    function [INDEX_WIDTH-1:0] get_hash_index;
        input [KEY_WIDTH-1:0] key;
        reg [31:0] hash_value;
        begin
            if (HASH_ALGORITHM == "SHA1")
                hash_value = sha1_hash(key);
            else // Default to FNV1A
                hash_value = fnv1a_hash(key);
                
            get_hash_index = hash_value[INDEX_WIDTH-1:0];
        end
    endfunction
    
    // Find slot for key (used for both read and write)
    function [INDEX_WIDTH-1:0] find_slot;
        input [KEY_WIDTH-1:0] key;
        input operation;  // 0 for read, 1 for write
        
        reg [INDEX_WIDTH-1:0] index;
        reg [INDEX_WIDTH-1:0] first_tombstone;
        reg found_tombstone;
        integer i;
        begin
            index = get_hash_index(key);
            found_tombstone = 0;
            first_tombstone = 0;
            
            if (COLLISION_METHOD == "LINEAR_PROBE") begin
                // Linear probing
                for (i = 0; i < TABLE_SIZE; i = i + 1) begin
                    // Calculate probe index
                    index = (get_hash_index(key) + i) & (TABLE_SIZE - 1);
                    
                    // For reading: return if key matches or empty slot found
                    if (!operation) begin  // Read operation
                        if (valid[index] && keys[index] == key) begin
                            find_slot = index;
                            return;
                        end
                        if (!valid[index] && !tomb[index]) begin
                            find_slot = TABLE_SIZE;  // Not found
                            return;
                        end
                    end
                    // For writing: return if empty slot or matching key found
                    else begin  // Write operation
                        if (!valid[index]) begin
                            // Use first tombstone if available, otherwise use this empty slot
                            if (tomb[index] && !found_tombstone) begin
                                first_tombstone = index;
                                found_tombstone = 1;
                            end
                            if (!tomb[index]) begin
                                find_slot = found_tombstone ? first_tombstone : index;
                                return;
                            end
                        end
                        if (valid[index] && keys[index] == key) begin
                            find_slot = index;  // Update existing entry
                            return;
                        end
                    end
                end
                
                // If we get here during write and found a tombstone, use it
                if (operation && found_tombstone) begin
                    find_slot = first_tombstone;
                    return;
                end
                
                // Table full or key not found
                find_slot = TABLE_SIZE;
            end
            else begin
                // For other collision methods (not fully implemented here)
                // This is a placeholder for future expansion
                find_slot = index;
            end
        end
    endfunction
    
    // Initialize hash table
    integer j;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (j = 0; j < TABLE_SIZE; j = j + 1) begin
                valid[j] <= 0;
                tomb[j] <= 0;
                keys[j] <= 0;
                values[j] <= 0;
            end
            entry_count <= 0;
            collisions <= 0;
            wr_done <= 0;
            wr_collision <= 0;
            rd_valid <= 0;
            rd_miss <= 0;
            del_done <= 0;
        end
        else begin
            // Default values
            wr_done <= 0;
            rd_valid <= 0;
            rd_miss <= 0;
            del_done <= 0;
            wr_collision <= 0;
            
            // Write operation
            if (wr_en) begin
                reg [INDEX_WIDTH-1:0] index;
                index = find_slot(wr_key, 1);
                
                if (index < TABLE_SIZE) begin
                    // If this is a new entry (not an update)
                    if (!valid[index] || keys[index] != wr_key) begin
                        if (index != get_hash_index(wr_key)) begin
                            collisions <= collisions + 1;
                            wr_collision <= 1;
                        end
                        
                        if (!valid[index] && !tomb[index]) begin
                            entry_count <= entry_count + 1;
                        end
                        else if (tomb[index]) begin
                            tomb[index] <= 0;  // Clear tombstone
                        end
                    end
                    
                    // Write the key/value
                    keys[index] <= wr_key;
                    values[index] <= wr_value;
                    valid[index] <= 1;
                    wr_done <= 1;
                end
                else begin
                    // Table full
                    wr_collision <= 1;
                end
            end
            
            // Read operation
            if (rd_en) begin
                reg [INDEX_WIDTH-1:0] index;
                index = find_slot(rd_key, 0);
                
                if (index < TABLE_SIZE && valid[index]) begin
                    rd_value <= values[index];
                    rd_valid <= 1;
                end
                else begin
                    rd_miss <= 1;
                    rd_value <= 0;
                end
            end
            
            // Delete operation
            if (del_en) begin
                reg [INDEX_WIDTH-1:0] index;
                index = find_slot(del_key, 0);
                
                if (index < TABLE_SIZE && valid[index]) begin
                    valid[index] <= 0;
                    tomb[index] <= 1;  // Mark as tombstone for probing
                    entry_count <= entry_count - 1;
                end
                
                del_done <= 1;
            end
        end
    end
endmodule
