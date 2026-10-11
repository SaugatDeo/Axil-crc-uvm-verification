class axis_driver extends uvm_driver #(axis_item);
  `uvm_component_utils(axis_driver)

  virtual axis_if vif;
  uvm_analysis_port #(axis_item) intent_ap;
  time last_ev;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    intent_ap = new("intent_ap", this);
    if (!uvm_config_db#(virtual axis_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axis_if not set for driver")
  endfunction

  task run_phase(uvm_phase phase);
    vif.tvalid <= 0;
    vif.tlast  <= 0;
    wait (vif.rstn === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      send(req);
      seq_item_port.item_done();
    end
  endtask

  task tick();
    @(posedge vif.clk);
    last_ev = $time;
  endtask

  task send(axis_item t);
    intent_ap.write(t);
    if ($time != last_ev) tick();
    foreach (t.raw[i]) begin
      if (i < t.gap.size() && t.gap[i] != 0) begin
        vif.tvalid <= 0;
        repeat (t.gap[i]) tick();
      end
      vif.tdata  <= t.raw[i];
      vif.tlast  <= (i == t.raw.size() - 1);
      vif.tvalid <= 1;
      do tick(); while (!vif.tready);
    end
    vif.tvalid <= 0;
    vif.tlast  <= 0;
  endtask
endclass