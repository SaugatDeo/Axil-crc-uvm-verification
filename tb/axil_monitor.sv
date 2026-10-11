class axil_monitor extends uvm_monitor;
  `uvm_component_utils(axil_monitor)

  virtual axil_if vif;
  uvm_analysis_port #(axil_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual axil_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axil_if not set for monitor")
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.rstn === 1'b1);
    fork
      mon_wr();
      mon_rd();
    join
  endtask

  task mon_wr();
    axil_item it;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.awvalid && vif.mon_cb.awready &&
          vif.mon_cb.wvalid  && vif.mon_cb.wready) begin
        it      = axil_item::type_id::create("wr");
        it.kind = AXIL_WR;
        it.addr = vif.mon_cb.awaddr;
        it.data = vif.mon_cb.wdata;
        do @(vif.mon_cb); while (!(vif.mon_cb.bvalid && vif.mon_cb.bready));
        it.resp = vif.mon_cb.bresp;
        ap.write(it);
      end
    end
  endtask

  task mon_rd();
    axil_item it;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.arvalid && vif.mon_cb.arready) begin
        it      = axil_item::type_id::create("rd");
        it.kind = AXIL_RD;
        it.addr = vif.mon_cb.araddr;
        do @(vif.mon_cb); while (!(vif.mon_cb.rvalid && vif.mon_cb.rready));
        it.rdata = vif.mon_cb.rdata;
        it.resp  = vif.mon_cb.rresp;
        ap.write(it);
      end
    end
  endtask
endclass