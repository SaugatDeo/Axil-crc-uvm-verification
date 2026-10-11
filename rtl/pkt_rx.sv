module pkt_rx (
  input  logic       clk,
  input  logic       rstn,
  input  logic       clr,
  input  logic       en,
  input  logic [7:0] tdata,
  input  logic       tvalid,
  input  logic       tlast,
  output logic       tready,
  input  logic       fifo_full,
  output logic       push,
  output logic [7:0] entry
);
  localparam logic [31:0] RESIDUE   = 32'hDEBB20E3;
  localparam int          MIN_BYTES = 5;
  localparam int          MAX_BYTES = 64;

  function automatic logic [31:0] crc32_byte(input logic [31:0] crc,
                                             input logic [7:0]  d);
    logic [31:0] c;
    c = crc ^ {24'b0, d};
    for (int i = 0; i < 8; i++)
      c = c[0] ? (c >> 1) ^ 32'hEDB88320 : (c >> 1);
    return c;
  endfunction

  logic [31:0] crc, crc_nxt;
  logic [7:0]  nbytes;
  logic [8:0]  total;
  logic        len_ok, crc_ok;
  logic [6:0]  len;

  assign tready = en && !fifo_full;

  wire beat = tvalid && tready;

  always_comb begin
    crc_nxt = crc32_byte(crc, tdata);
    total   = {1'b0, nbytes} + 9'd1;
    len_ok  = (total >= MIN_BYTES) && (total <= MAX_BYTES);
    crc_ok  = len_ok && (crc_nxt == RESIDUE);
    if (total <= 9'd4)        len = 7'd0;
    else if (total > 9'd131)  len = 7'h7F;
    else                      len = total - 9'd4;
  end

  always_ff @(posedge clk) begin
    if (!rstn || clr || (beat && tlast)) begin
      crc    <= 32'hFFFF_FFFF;
      nbytes <= '0;
    end else if (beat) begin
      crc <= crc_nxt;
      if (nbytes != 8'hFF) nbytes <= nbytes + 1'b1;
    end
  end

  assign push  = beat && tlast;
  assign entry = {crc_ok, len};
endmodule