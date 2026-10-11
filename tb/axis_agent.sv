typedef uvm_sequencer #(axis_item) axis_sequencer;

class axis_agent extends uvm_agent;
  `uvm_component_utils(axis_agent)

  axis_sequencer sqr;
  axis_driver    drv;
  axis_monitor   mon;
  uvm_analysis_port #(axis_item) ap;
  uvm_analysis_port #(axis_item) intent_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr       = axis_sequencer::type_id::create("sqr", this);
    drv       = axis_driver::type_id::create("drv", this);
    mon       = axis_monitor::type_id::create("mon", this);
    ap        = new("ap", this);
    intent_ap = new("intent_ap", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    mon.ap.connect(ap);
    drv.intent_ap.connect(intent_ap);
  endfunction
endclass