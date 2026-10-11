class axis_monitor extends uvm_monitor;
  `uvm_component_utils(axis_monitor)

  virtual axis_if vif;
  uvm_analysis_port #(axis_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual axis_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axis_if not set for monitor")
  endfunction

  task run_phase(uvm_phase phase);
    axis_item it = axis_item::type_id::create("it");
    wait (vif.rstn === 1'b1);
    forever begin
      @(vif.mon_cb);
      if (vif.rstn === 1'b0) begin
        it.raw.delete();
        continue;
      end
      if (vif.mon_cb.tvalid && vif.mon_cb.tready) begin
        it.raw.push_back(vif.mon_cb.tdata);
        if (vif.mon_cb.tlast) begin
          it.plen = (it.raw.size() > 4) ? it.raw.size() - 4 : 0;
          ap.write(it);
          it = axis_item::type_id::create("it");
        end
      end
    end
  endtask
endclass