class axil_reg_seq extends uvm_sequence #(axil_item);
  `uvm_object_utils(axil_reg_seq)

  axil_kind_e s_kind;
  bit [7:0]   s_addr;
  bit [31:0]  s_data;
  bit [31:0]  rdata;
  bit [1:0]   resp;

  function new(string name = "axil_reg_seq");
    super.new(name);
  endfunction

  task body();
    axil_item t = axil_item::type_id::create("t");
    start_item(t);
    if (!t.randomize() with { kind == s_kind; addr == s_addr; data == s_data; })
      `uvm_fatal("RAND", "axil_item randomize failed")
    finish_item(t);
    rdata = t.rdata;
    resp  = t.resp;
  endtask
endclass

class axis_pkt_seq extends uvm_sequence #(axis_item);
  `uvm_object_utils(axis_pkt_seq)

  int unsigned s_plen = 9;
  bit          s_corrupt;

  function new(string name = "axis_pkt_seq");
    super.new(name);
  endfunction

  task body();
    axis_item t = axis_item::type_id::create("t");
    start_item(t);
    if (!t.randomize() with { plen == s_plen; corrupt == s_corrupt; })
      `uvm_fatal("RAND", "axis_item randomize failed")
    finish_item(t);
  endtask
endclass