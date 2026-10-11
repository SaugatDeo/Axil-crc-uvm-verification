typedef uvm_sequencer #(axil_item) axil_sequencer;

class axil_agent extends uvm_agent;
  `uvm_component_utils(axil_agent)

  axil_sequencer sqr;
  axil_driver    drv;
  axil_monitor   mon;
  uvm_analysis_port #(axil_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = axil_sequencer::type_id::create("sqr", this);
    drv = axil_driver::type_id::create("drv", this);
    mon = axil_monitor::type_id::create("mon", this);
    ap  = new("ap", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    mon.ap.connect(ap);
  endfunction
endclass