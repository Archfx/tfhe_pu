`timescale 1 ns / 1 ps

module tfhe_w_controller #
(
  parameter integer C_S_AXI_DATA_WIDTH = 32,
  parameter integer C_S_AXI_ADDR_WIDTH = 6   // 6 regs → 0x00–0x14
)
(
  // --------------------------------------------------
  // TFHE processor inputs (module-controlled state)
  // --------------------------------------------------
  input  wire [C_S_AXI_DATA_WIDTH-1:0] host_rd_addr,
  input  wire [C_S_AXI_DATA_WIDTH-1:0] host_rd_len,
  input  wire                          pbs_busy,
  input  wire                          pbs_done,

  // --------------------------------------------------
  // Controller outputs
  // --------------------------------------------------
  output wire [C_S_AXI_DATA_WIDTH-1:0] host_wr_addr,
  output wire [C_S_AXI_DATA_WIDTH-1:0] host_wr_len,
  output wire                          start_pbs,

  // --------------------------------------------------
  // AXI4-Lite interface
  // --------------------------------------------------
  input  wire                          S_AXI_ACLK,
  input  wire                          S_AXI_ARESETN,

  input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
  input  wire                          S_AXI_AWVALID,
  output reg                           S_AXI_AWREADY,

  input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
  input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
  input  wire                          S_AXI_WVALID,
  output reg                           S_AXI_WREADY,

  output reg  [1:0]                    S_AXI_BRESP,
  output reg                           S_AXI_BVALID,
  input  wire                          S_AXI_BREADY,

  input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
  input  wire                          S_AXI_ARVALID,
  output reg                           S_AXI_ARREADY,

  output reg  [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
  output reg  [1:0]                    S_AXI_RRESP,
  output reg                           S_AXI_RVALID,
  input  wire                          S_AXI_RREADY
);

  // --------------------------------------------------
  // Register Map
  // --------------------------------------------------
  // 0x00 CTRL     (W/R) bit0 = START (W1P)
  // 0x04 WR_ADDR  (W/R)
  // 0x08 WR_LEN   (W/R)
  // 0x0C STATUS   (R)   bit0=busy, bit1=done
  // 0x10 RD_ADDR  (R)   from TFHE processor
  // 0x14 RD_LEN   (R)   from TFHE processor
  // --------------------------------------------------

  localparam integer ADDR_LSB = 2;
  wire [2:0] aw_sel = S_AXI_AWADDR[ADDR_LSB+2:ADDR_LSB];
  wire [2:0] ar_sel = S_AXI_ARADDR[ADDR_LSB+2:ADDR_LSB];

  // --------------------------------------------------
  // Slave registers
  // --------------------------------------------------
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0; // CTRL
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1; // WR_ADDR
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2; // WR_LEN
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3; // STATUS
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4; // RD_ADDR 
  reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg5; // RD_LEN  

  assign host_wr_addr = slv_reg1;
  assign host_wr_len  = slv_reg2;

  // --------------------------------------------------
  // AXI write channel
  // --------------------------------------------------
  wire write_en = S_AXI_AWVALID && S_AXI_WVALID &&
                  S_AXI_AWREADY && S_AXI_WREADY;

  always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      S_AXI_AWREADY <= 1'b0;
      S_AXI_WREADY  <= 1'b0;
      S_AXI_BVALID  <= 1'b0;
      S_AXI_BRESP   <= 2'b00;
    end else begin
      S_AXI_AWREADY <= ~S_AXI_BVALID;
      S_AXI_WREADY  <= ~S_AXI_BVALID;

      if (write_en) begin
        S_AXI_BVALID <= 1'b1;
        S_AXI_BRESP  <= 2'b00;
      end else if (S_AXI_BVALID && S_AXI_BREADY) begin
        S_AXI_BVALID <= 1'b0;
      end
    end
  end

  // --------------------------------------------------
  // Register write logic (host writes reg0–reg2 only)
  // --------------------------------------------------
  integer b;
  always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      slv_reg0 <= 0;
      slv_reg1 <= 0;
      slv_reg2 <= 0;
    end else if (write_en) begin
      case (aw_sel)
        3'h0: for (b=0;b<C_S_AXI_DATA_WIDTH/8;b=b+1)
                if (S_AXI_WSTRB[b]) slv_reg0[b*8+:8] <= S_AXI_WDATA[b*8+:8];
        3'h1: for (b=0;b<C_S_AXI_DATA_WIDTH/8;b=b+1)
                if (S_AXI_WSTRB[b]) slv_reg1[b*8+:8] <= S_AXI_WDATA[b*8+:8];
        3'h2: for (b=0;b<C_S_AXI_DATA_WIDTH/8;b=b+1)
                if (S_AXI_WSTRB[b]) slv_reg2[b*8+:8] <= S_AXI_WDATA[b*8+:8];
        default: ; // ignore writes to RO regs
      endcase
    end
  end

  // --------------------------------------------------
  // start_pbs (W1P from CTRL bit0)
  // --------------------------------------------------
  reg start_pbs_r;
  always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN)
      start_pbs_r <= 1'b0;
    else begin
      start_pbs_r <= 1'b0;
      if (write_en && aw_sel==3'h0 && S_AXI_WDATA[0])
        start_pbs_r <= 1'b1;
    end
  end
  assign start_pbs = start_pbs_r;

  // --------------------------------------------------
  // Module-controlled registers
  // --------------------------------------------------
  always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      slv_reg3 <= 64'b0;
      slv_reg4 <= 64'b0;
      slv_reg5 <= 64'b0;
    end else begin
      slv_reg3[0] <= pbs_busy;
      slv_reg3[1] <= pbs_done;
      slv_reg3[C_S_AXI_DATA_WIDTH-1:2] <= 64'b0;

      slv_reg4 <= host_rd_addr;
      slv_reg5 <= host_rd_len;
    end
  end

  // --------------------------------------------------
  // AXI read channel
  // --------------------------------------------------
  always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
      S_AXI_ARREADY <= 1'b0;
      S_AXI_RVALID  <= 1'b0;
      S_AXI_RRESP   <= 2'b00;
      S_AXI_RDATA   <= 0;
    end else begin
      S_AXI_ARREADY <= ~S_AXI_RVALID;

      if (S_AXI_ARVALID && S_AXI_ARREADY) begin
        S_AXI_RVALID <= 1'b1;
        S_AXI_RRESP  <= 2'b00;
        case (ar_sel)
          3'h0: S_AXI_RDATA <= slv_reg0;
          3'h1: S_AXI_RDATA <= slv_reg1;
          3'h2: S_AXI_RDATA <= slv_reg2;
          3'h3: S_AXI_RDATA <= slv_reg3;
          3'h4: S_AXI_RDATA <= slv_reg4;
          3'h5: S_AXI_RDATA <= slv_reg5;
          default: S_AXI_RDATA <= 0;
        endcase
      end else if (S_AXI_RVALID && S_AXI_RREADY) begin
        S_AXI_RVALID <= 1'b0;
      end
    end
  end

endmodule
