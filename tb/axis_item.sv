class axis_item extends uvm_sequence_item;
  rand int unsigned  plen;
  rand byte unsigned payload[];
  rand bit           corrupt;
  rand int unsigned  flip_idx;
  rand bit [7:0]     flip_mask;
  rand int unsigned  gap[];

  byte unsigned      raw[$];

  constraint c_len  { soft plen inside {[1:60]}; plen <= 300; }
  constraint c_pay  { payload.size() == plen; }
  constraint c_corr { corrupt dist { 0 := 8, 1 := 2 }; }
  constraint c_flip { flip_idx < plen + 4; flip_mask != 0; }
  constraint c_gap  {
    gap.size() == plen + 4;
    foreach (gap[i]) gap[i] dist { 0 := 8, [1:3] :/ 2 };
  }

  `uvm_object_utils(axis_item)

  function new(string name = "axis_item");
    super.new(name);
  endfunction

  static function bit [31:0] crc32(byte unsigned d[$]);
    bit [31:0] c = '1;
    foreach (d[i]) begin
      c ^= d[i];
      repeat (8) c = c[0] ? (c >> 1) ^ 32'hEDB88320 : (c >> 1);
    end
    return ~c;
  endfunction

  function void build_stream();
    byte unsigned p[$];
    bit [31:0]    crc;
    foreach (payload[i]) p.push_back(payload[i]);
    crc = crc32(p);
    raw = p;
    for (int i = 0; i < 4; i++) raw.push_back(crc[8*i +: 8]);
    if (corrupt) raw[flip_idx] ^= flip_mask;
  endfunction

  function void post_randomize();
    build_stream();
  endfunction

  function string convert2string();
    return $sformatf("plen=%0d bytes=%0d corrupt=%0b", plen, raw.size(), corrupt);
  endfunction
endclass