package tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "axil_item.sv"
  `include "axil_driver.sv"
  `include "axil_monitor.sv"
  `include "axil_agent.sv"

  `include "axis_item.sv"
  `include "axis_driver.sv"
  `include "axis_monitor.sv"
  `include "axis_agent.sv"

  `include "crc_sb.sv"
  `include "crc_cov.sv"
  `include "crc_env.sv"

  `include "seqs.sv"
  `include "tests.sv"
  `include "rand_tests.sv"
  `include "reg_tests.sv"
  `include "fifo_tests.sv"
  `include "race_tests.sv"
  `include "long_tests.sv"
  `include "ctrl_tests.sv"
endpackage