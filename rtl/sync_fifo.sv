module sync_fifo #(
  parameter int W     = 8,
  parameter int DEPTH = 8
)(
  input  logic         clk,
  input  logic         rstn,
  input  logic         clr,
  input  logic         push,
  input  logic [W-1:0] din,
  input  logic         pop,
  output logic [W-1:0] dout,
  output logic         empty,
  output logic         full
);
  localparam int AW = $clog2(DEPTH);

  logic [W-1:0]  mem [DEPTH];
  logic [AW-1:0] wp, rp;
  logic [AW:0]   cnt;

  wire do_push = push && !full;
  wire do_pop  = pop  && !empty;

  assign empty = (cnt == 0);
  assign full  = (cnt == DEPTH);
  assign dout  = mem[rp];

  always_ff @(posedge clk) begin
    if (!rstn || clr) begin
      wp  <= '0;
      rp  <= '0;
      cnt <= '0;
    end else begin
      if (do_push) begin
        mem[wp] <= din;
        wp      <= wp + 1'b1;
      end
      if (do_pop) rp <= rp + 1'b1;
      cnt <= cnt + do_push - do_pop;
    end
  end
endmodule