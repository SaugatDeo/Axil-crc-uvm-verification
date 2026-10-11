import "DPI-C" function void          ref_clear();
import "DPI-C" function void          ref_byte(input byte unsigned b);
import "DPI-C" function byte unsigned ref_result();

`uvm_analysis_imp_decl(_axis)
`uvm_analysis_imp_decl(_axil)
`uvm_analysis_imp_decl(_sent)

class crc_sb extends uvm_scoreboard;
  `uvm_component_utils(crc_sb)

  uvm_analysis_imp_axis #(axis_item, crc_sb) axis_imp;
  uvm_analysis_imp_axil #(axil_item, crc_sb) axil_imp;
  uvm_analysis_imp_sent #(axis_item, crc_sb) sent_imp;

  bit [7:0] exp_q[$];
  axis_item sent_q[$];
  int       checks, errors, n_sent, n_seen;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axis_imp = new("axis_imp", this);
    axil_imp = new("axil_imp", this);
    sent_imp = new("sent_imp", this);
  endfunction

  function bit [7:0] predict(byte unsigned raw[$]);
    ref_clear();
    foreach (raw[i]) ref_byte(raw[i]);
    return ref_result();
  endfunction

  function void write_sent(axis_item t);
    sent_q.push_back(t);
    n_sent++;
  endfunction

  function void write_axis(axis_item t);
    axis_item want;
    bit       same = 1;
    n_seen++;
    if (sent_q.size() == 0) begin
      errors++;
      `uvm_error("SB", "packet seen on the stream with no matching send")
      return;
    end
    want = sent_q.pop_front();
    if (want.raw.size() != t.raw.size()) same = 0;
    else foreach (want.raw[i]) if (want.raw[i] !== t.raw[i]) same = 0;
    if (!same) begin
      errors++;
      `uvm_error("SB", $sformatf("STREAM MISMATCH sent %0d bytes, saw %0d bytes",
                                  want.raw.size(), t.raw.size()))
    end
    exp_q.push_back(predict(want.raw));
  endfunction

  function void write_axil(axil_item t);
    bit [7:0] exp;
    if (t.kind != AXIL_RD || t.addr != 8'h08) return;
    exp = (exp_q.size() > 0) ? exp_q.pop_front() : 8'h00;
    checks++;
    if (t.resp != 2'b00 || t.rdata !== {24'h0, exp}) begin
      errors++;
      `uvm_error("SB", $sformatf("RESULT got %08h exp %02h resp %0d",
                                  t.rdata, exp, t.resp))
    end
  endfunction

  function void check_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("checks=%0d errors=%0d sent=%0d seen=%0d",
                              checks, errors, n_sent, n_seen), UVM_LOW)
    if (sent_q.size() != 0)
      `uvm_error("SB", $sformatf("%0d packets sent but never seen on the stream",
                                  sent_q.size()))
    if (checks == 0) `uvm_error("SB", "no RESULT reads were checked")
  endfunction
endclass