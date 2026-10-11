class crc_env extends uvm_env;
  `uvm_component_utils(crc_env)

  axil_agent axil;
  axis_agent axis;
  crc_sb     sb;
  crc_cov    cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    axil = axil_agent::type_id::create("axil", this);
    axis = axis_agent::type_id::create("axis", this);
    sb   = crc_sb::type_id::create("sb", this);
    cov  = crc_cov::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    axis.intent_ap.connect(sb.sent_imp);
    axis.ap.connect(sb.axis_imp);
    axil.ap.connect(sb.axil_imp);
    axis.ap.connect(cov.axis_imp);
    axil.ap.connect(cov.axil_imp);
  endfunction
endclass