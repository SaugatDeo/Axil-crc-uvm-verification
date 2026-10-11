typedef enum bit { AXIL_RD, AXIL_WR } axil_kind_e;

class axil_item extends uvm_sequence_item;
  rand axil_kind_e   kind;
  rand bit [7:0]     addr;
  rand bit [31:0]    data;
  rand int unsigned  delay;

  bit [1:0]          resp;
  bit [31:0]         rdata;

  constraint c_align { addr[1:0] == 2'b00; }
  constraint c_map   { soft addr <= 8'h10; }
  constraint c_delay { delay dist { 0 := 6, [1:3] := 3, [4:8] := 1 }; }

  `uvm_object_utils(axil_item)

  function new(string name = "axil_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("%s addr=%02h data=%08h resp=%0d",
                     kind.name(), addr, (kind == AXIL_WR) ? data : rdata, resp);
  endfunction
endclass