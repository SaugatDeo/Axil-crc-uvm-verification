class crc_cov extends uvm_component;
  `uvm_component_utils(crc_cov)

  uvm_analysis_imp_axis #(axis_item, crc_cov) axis_imp;
  uvm_analysis_imp_axil #(axil_item, crc_cov) axil_imp;

  int unsigned total;
  bit [7:0]    addr;
  axil_kind_e  kind;
  bit [1:0]    resp;
  bit [31:0]   rdata;

  covergroup cg_pkt;
    cp_total: coverpoint total {
      bins short_pkt = {[0:4]};
      bins min_len   = {5};
      bins mid_len   = {[6:63]};
      bins max_len   = {64};
      bins long_pkt  = {[65:$]};
    }
  endgroup

  covergroup cg_bus;
    cp_addr: coverpoint addr {
      bins ctrl     = {8'h00};
      bins status   = {8'h04};
      bins result   = {8'h08};
      bins irq_en   = {8'h0C};
      bins irq_stat = {8'h10};
      bins unmapped = default;
    }
    cp_kind: coverpoint kind;
    cp_resp: coverpoint resp { bins okay = {2'b00}; bins slverr = {2'b10}; }
    x_addr_kind: cross cp_addr, cp_kind;
  endgroup

  covergroup cg_res;
    cp_ok:  coverpoint rdata[7];
    cp_len: coverpoint rdata[6:0] {
      bins zero   = {0};
      bins one    = {1};
      bins mid    = {[2:58]};
      bins max_ok = {[59:60]};
      bins over   = {[61:127]};
    }
  endgroup

  covergroup cg_stat;
    cp_empty: coverpoint rdata[0];
    cp_full:  coverpoint rdata[1];
    cp_err:   coverpoint rdata[2];
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_pkt  = new();
    cg_bus  = new();
    cg_res  = new();
    cg_stat = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axis_imp = new("axis_imp", this);
    axil_imp = new("axil_imp", this);
  endfunction

  function void write_axis(axis_item t);
    total = t.raw.size();
    cg_pkt.sample();
  endfunction

  function void write_axil(axil_item t);
    addr  = t.addr;
    kind  = t.kind;
    resp  = t.resp;
    rdata = t.rdata;
    cg_bus.sample();
    if (t.kind == AXIL_RD && t.resp == 2'b00) begin
      if (t.addr == 8'h08) cg_res.sample();
      if (t.addr == 8'h04) cg_stat.sample();
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("pkt %0.1f  bus %0.1f  result %0.1f  status %0.1f",
              cg_pkt.get_coverage(), cg_bus.get_coverage(),
              cg_res.get_coverage(), cg_stat.get_coverage()), UVM_LOW)
  endfunction
endclass