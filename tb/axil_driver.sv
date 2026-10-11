class axil_driver extends uvm_driver #(axil_item);
  `uvm_component_utils(axil_driver)

  virtual axil_if vif;
  bit             slow_ready;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axil_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axil_if not set for driver")
  endfunction

  task run_phase(uvm_phase phase);
    idle();
    wait (vif.rstn === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      if (req.kind == AXIL_WR) do_write(req);
      else                     do_read(req);
      seq_item_port.item_done();
    end
  endtask

  task idle();
    vif.drv_cb.awvalid <= 0;
    vif.drv_cb.wvalid  <= 0;
    vif.drv_cb.arvalid <= 0;
    vif.drv_cb.bready  <= 1;
    vif.drv_cb.rready  <= 1;
  endtask

  task do_write(axil_item t);
    repeat (t.delay) @(vif.drv_cb);
    vif.drv_cb.bready  <= !slow_ready;
    vif.drv_cb.awaddr  <= t.addr;
    vif.drv_cb.wdata   <= t.data;
    vif.drv_cb.wstrb   <= 4'hF;
    vif.drv_cb.awvalid <= 1;
    vif.drv_cb.wvalid  <= 1;
    do @(vif.drv_cb); while (!(vif.drv_cb.awready && vif.drv_cb.wready));
    vif.drv_cb.awvalid <= 0;
    vif.drv_cb.wvalid  <= 0;
    do @(vif.drv_cb); while (!vif.drv_cb.bvalid);
    t.resp = vif.drv_cb.bresp;
    if (slow_ready) begin
      repeat ($urandom_range(0, 4)) @(vif.drv_cb);
      vif.drv_cb.bready <= 1;
      do @(vif.drv_cb); while (vif.drv_cb.bvalid);
      vif.drv_cb.bready <= 0;
    end
  endtask

  task do_read(axil_item t);
    repeat (t.delay) @(vif.drv_cb);
    vif.drv_cb.rready  <= !slow_ready;
    vif.drv_cb.araddr  <= t.addr;
    vif.drv_cb.arvalid <= 1;
    do @(vif.drv_cb); while (!vif.drv_cb.arready);
    vif.drv_cb.arvalid <= 0;
    do @(vif.drv_cb); while (!vif.drv_cb.rvalid);
    t.rdata = vif.drv_cb.rdata;
    t.resp  = vif.drv_cb.rresp;
    if (slow_ready) begin
      repeat ($urandom_range(0, 4)) @(vif.drv_cb);
      vif.drv_cb.rready <= 1;
      do @(vif.drv_cb); while (vif.drv_cb.rvalid);
      vif.drv_cb.rready <= 0;
    end
  endtask
endclass