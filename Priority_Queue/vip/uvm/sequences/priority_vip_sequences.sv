class priority_vip_base_seq extends uvm_sequence #(priority_vip_seq_item);
    `uvm_object_utils(priority_vip_base_seq)
    function new(string name="priority_vip_base_seq");
        super.new(name);
    endfunction
    task send(input int op=0, input pq_priority_t priority_value='0,
              input pq_data_t data='0, input int stalls=0,
              input bit reset=0, input int abort_after=-1);
        priority_vip_seq_item item;
        item = priority_vip_seq_item::type_id::create("item");
        start_item(item);
        item.op = 2'(op);
        item.priority_value = priority_value;
        item.data = data;
        item.stalls = stalls;
        item.reset = reset;
        item.abort_after = abort_after;
        finish_item(item);
    endtask
endclass

class priority_vip_boundary_seq extends priority_vip_base_seq;
    `uvm_object_utils(priority_vip_boundary_seq)
    function new(string name="priority_vip_boundary_seq");
        super.new(name);
    endfunction
    task body();
        send(.reset(1));
        send(.op(1), .stalls(3)); send(.op(2), .stalls(3)); send(.op(3), .stalls(3));
        for (int pattern = 0; pattern < 3; pattern++) begin
            for (int i = 0; i < DEPTH; i++)
                send(0, pq_priority_t'(pattern == 0 ? i : pattern == 1 ? DEPTH-i : 0), pq_data_t'(i), i%3);
            send(.stalls(2)); send(.op(3));
            repeat (DEPTH) begin
                send(.op(2)); send(.op(2), .stalls(2)); send(.op(1), .stalls(1));
            end
        end
        send(.op(1));
    endtask
endclass

class priority_vip_random_seq extends priority_vip_base_seq;
    `uvm_object_utils(priority_vip_random_seq)
    function new(string name="priority_vip_random_seq");
        super.new(name);
    endfunction
    task body();
        pq_priority_t priority_value;
        pq_data_t data;
        int selection;
        send(.reset(1));
        repeat (400) begin
            foreach (priority_value[i]) priority_value[i] = 1'($urandom_range(0, 1));
            foreach (data[i]) data[i] = 1'($urandom_range(0, 1));
            selection = int'($urandom_range(0, 99));
            send(selection < 45 ? 0 : selection < 80 ? 1 : selection < 95 ? 2 : 3,
                 priority_value, data, int'($urandom_range(0, 4)));
        end
        repeat (DEPTH+1) send(.op(1));
    endtask
endclass

class priority_vip_reset_seq extends priority_vip_base_seq;
    `uvm_object_utils(priority_vip_reset_seq)
    function new(string name="priority_vip_reset_seq");
        super.new(name);
    endfunction
    task body();
        for (int op = 0; op < 3; op++) begin
            for (int delay_cycles = 0; delay_cycles < $clog2(DEPTH+1)+2; delay_cycles++) begin
                send(.reset(1));
                for (int i = 0; i < (DEPTH > 1 ? DEPTH-1 : 1); i++) send(0, pq_priority_t'(i), pq_data_t'(i));
                send(op, MIN_FIRST ? '0 : '1, '1, 0, 0, delay_cycles);
                send(.op(1));
                send(0, '1, '1);
                send(.op(1));
            end
        end
    endtask
endclass
