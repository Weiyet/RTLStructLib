class bitmap_vip_sequence extends uvm_sequence #(bitmap_vip_seq_item);
    `uvm_object_utils(bitmap_vip_sequence)
    string scenario = "boundary";
    function new(string name = "bitmap_vip_sequence"); super.new(name); endfunction
    task send(bit a = 0, bit f = 0, int id = 0, bit reset = 0);
        bitmap_vip_seq_item item;
        item = bitmap_vip_seq_item::type_id::create("item");
        start_item(item);
        item.alloc_req = a; item.free_req = f; item.free_id = ID_WIDTH'(id); item.rst = reset;
        finish_item(item);
    endtask
    task body();
        bit [31:0] r;
        send(1, 1, 0, 1);
        send();
        if (scenario == "random") begin
            for (int i = 0; i < 600; i++) begin
                r = $urandom;
                send(r[0], r[1], int'(r >> 2), (i % 113) == 112);
            end
        end else if (scenario == "reset") begin
            repeat (3) begin
                repeat (CAPACITY) send(1);
                send(1, 1, CAPACITY-1, 1);
                send();
                send(1); send(1, 1, 0); send(0, 0, 0, 1);
            end
        end else begin
            send(0, 1, 0); send(1, 1, 0); send(0, 1, 0);
            repeat (2) begin
                repeat (CAPACITY+1) send(1);
                for (int i = CAPACITY-1; i >= 0; i--) send(1, 1, i);
                for (int i = CAPACITY-1; i >= 0; i--) begin send(0, 1, i); send(0, 1, i); end
            end
            for (int i = CAPACITY; i < 2**ID_WIDTH; i++) begin send(0, 1, i); send(1, 1, i); end
            send(0, 0, 0, 1);
            repeat (CAPACITY) send(1);
            send(0, 1, 0); send(1, 1, CAPACITY-1);
        end
        send(1, 1, 0, 1);
        repeat (CAPACITY+1) send(1);
        for (int i = 0; i < CAPACITY; i++) send(0, 1, i);
        send();
    endtask
endclass
