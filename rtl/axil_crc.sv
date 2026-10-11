module axil_crc (
  input  logic        clk,
  input  logic        rstn,

  input  logic [7:0]  s_axil_awaddr,
  input  logic        s_axil_awvalid,
  output logic        s_axil_awready,
  input  logic [31:0] s_axil_wdata,
  input  logic [3:0]  s_axil_wstrb,
  input  logic        s_axil_wvalid,
  output logic        s_axil_wready,
  output logic [1:0]  s_axil_bresp,
  output logic        s_axil_bvalid,
  input  logic        s_axil_bready,
  input  logic [7:0]  s_axil_araddr,
  input  logic        s_axil_arvalid,
  output logic        s_axil_arready,
  output logic [31:0] s_axil_rdata,
  output logic [1:0]  s_axil_rresp,
  output logic        s_axil_rvalid,
  input  logic        s_axil_rready,

  input  logic [7:0]  s_axis_tdata,
  input  logic        s_axis_tvalid,
  input  logic        s_axis_tlast,
  output logic        s_axis_tready,

  output logic        irq
);
  localparam logic [1:0] OKAY   = 2'b00, SLVERR = 2'b10;
  localparam logic [5:0] A_CTRL = 6'h00, A_STATUS = 6'h01, A_RESULT = 6'h02,
                         A_IRQEN = 6'h03, A_IRQST = 6'h04;

  logic       enable, irq_en, irq_stat, crc_err_seen, clr;
  logic       rx_push, fifo_pop, fifo_empty, fifo_full;
  logic [7:0] rx_entry, fifo_dout;

  pkt_rx u_rx (
    .clk(clk), .rstn(rstn), .clr(clr), .en(enable),
    .tdata(s_axis_tdata), .tvalid(s_axis_tvalid), .tlast(s_axis_tlast),
    .tready(s_axis_tready), .fifo_full(fifo_full),
    .push(rx_push), .entry(rx_entry)
  );

  sync_fifo #(.W(8), .DEPTH(8)) u_fifo (
    .clk(clk), .rstn(rstn), .clr(clr),
    .push(rx_push), .din(rx_entry), .pop(fifo_pop),
    .dout(fifo_dout), .empty(fifo_empty), .full(fifo_full)
  );

  // write channel
  wire       wr_go   = s_axil_awvalid && s_axil_wvalid && !s_axil_bvalid;
  wire [5:0] waddr   = s_axil_awaddr[7:2];
  wire       irq_w1c = wr_go && (waddr == A_IRQST) && s_axil_wdata[0];

  assign s_axil_awready = wr_go;
  assign s_axil_wready  = wr_go;

  always_ff @(posedge clk) begin
    if (!rstn) begin
      enable        <= 1'b0;
      irq_en        <= 1'b0;
      clr           <= 1'b0;
      s_axil_bvalid <= 1'b0;
      s_axil_bresp  <= OKAY;
    end else begin
      clr <= 1'b0;
      if (s_axil_bvalid && s_axil_bready) s_axil_bvalid <= 1'b0;
      if (wr_go) begin
        s_axil_bvalid <= 1'b1;
        s_axil_bresp  <= OKAY;
        case (waddr)
          A_CTRL:  begin enable <= s_axil_wdata[0]; clr <= s_axil_wdata[1]; end
          A_IRQEN: irq_en <= s_axil_wdata[0];
          A_IRQST: ;
          default: s_axil_bresp <= SLVERR;
        endcase
      end
    end
  end

  // read channel
  logic [31:0] rd_data;
  logic        rd_err, rd_pop;

  always_comb begin
    rd_data = '0;
    rd_err  = 1'b0;
    rd_pop  = 1'b0;
    case (s_axil_araddr[7:2])
      A_CTRL:   rd_data[0]   = enable;
      A_STATUS: rd_data[2:0] = {crc_err_seen, fifo_full, fifo_empty};
      A_RESULT: if (!fifo_empty) begin
                  rd_data[7:0] = fifo_dout;
                  rd_pop       = 1'b1;
                end
      A_IRQEN:  rd_data[0]   = irq_en;
      A_IRQST:  rd_data[0]   = irq_stat;
      default:  rd_err       = 1'b1;
    endcase
  end

  wire rd_go = s_axil_arvalid && !s_axil_rvalid;

  assign s_axil_arready = rd_go;
  assign fifo_pop       = rd_go && rd_pop;

  always_ff @(posedge clk) begin
    if (!rstn) begin
      s_axil_rvalid <= 1'b0;
      s_axil_rdata  <= '0;
      s_axil_rresp  <= OKAY;
    end else begin
      if (rd_go) begin
        s_axil_rvalid <= 1'b1;
        s_axil_rdata  <= rd_data;
        s_axil_rresp  <= rd_err ? SLVERR : OKAY;
      end else if (s_axil_rready) begin
        s_axil_rvalid <= 1'b0;
      end
    end
  end

  // status and interrupt
  always_ff @(posedge clk) begin
    if (!rstn || clr) begin
      crc_err_seen <= 1'b0;
      irq_stat     <= 1'b0;
    end else begin
      if (rx_push && !rx_entry[7]) crc_err_seen <= 1'b1;
      if (rx_push)                 irq_stat     <= 1'b1;
      else if (irq_w1c)            irq_stat     <= 1'b0;
    end
  end

  assign irq = irq_stat & irq_en;
endmodule