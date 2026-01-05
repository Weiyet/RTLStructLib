//////////////////////////////////////////////////////////////////////////////////
// Create Date: 01/04/2026
// Module Name: table_vip_monitor
//////////////////////////////////////////////////////////////////////////////////

class table_vip_monitor extends uvm_monitor;
    `uvm_component_utils(table_vip_monitor)

    virtual table_vip_if vif;
    table_vip_config cfg;
    uvm_analysis_port #(table_vip_seq_item) ap;

    function new(string name = "table_vip_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual table_vip_if)::get(this, "", "table_vip_vif", vif))
            `uvm_fatal("MONITOR", "No virtual interface")
        if (!uvm_config_db#(table_vip_config)::get(this, "", "table_vip_cfg", cfg))
            `uvm_fatal("MONITOR", "No config")
    endfunction

    task run_phase(uvm_phase phase);
        table_vip_seq_item item;

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.wr_en != 2'b00) begin
                item = table_vip_seq_item::type_id::create("item");
                item.op = WRITE;
                item.wr_en = vif.mon_cb.wr_en;
                item.rd_en = 0;

                // Unpack write indices
                item.index_wr[0] = vif.mon_cb.index_wr[4:0];
                item.index_wr[1] = vif.mon_cb.index_wr[9:5];

                // Unpack write data
                item.data_wr[0] = vif.mon_cb.data_wr[7:0];
                item.data_wr[1] = vif.mon_cb.data_wr[15:8];

                ap.write(item);
                `uvm_info("MONITOR", $sformatf("Observed %s", item.convert2string()), UVM_HIGH)
            end

            if (vif.mon_cb.rd_en) begin
                item = table_vip_seq_item::type_id::create("item");
                item.op = READ;
                item.rd_en = 1;
                item.wr_en = 2'b00;

                // Unpack read indices
                item.index_rd[0] = vif.mon_cb.index_rd[4:0];
                item.index_rd[1] = vif.mon_cb.index_rd[9:5];

                @(vif.mon_cb);

                // Unpack read data
                item.data_rd[0] = vif.mon_cb.data_rd[7:0];
                item.data_rd[1] = vif.mon_cb.data_rd[15:8];

                ap.write(item);
                `uvm_info("MONITOR", $sformatf("Observed %s", item.convert2string()), UVM_HIGH)
            end
        end
    endtask

endclass
