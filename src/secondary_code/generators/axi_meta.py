#!/usr/bin/env python3

def iface_param(busif_name: str, clk_domain: str) -> str:
    # This matches the style/fields you pasted from the HBM top module.
    return (
        f"XIL_INTERFACENAME {busif_name}, "
        f"DATA_WIDTH 256, PROTOCOL AXI3, FREQ_HZ 250000000, "
        f"ID_WIDTH 6, ADDR_WIDTH 33, "
        f"AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, "
        f"READ_WRITE_MODE READ_WRITE, "
        f"HAS_BURST 1, HAS_LOCK 0, HAS_PROT 0, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, "
        f"HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, "
        f"SUPPORTS_NARROW_BURST 1, "
        f"NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, "
        f"MAX_BURST_LENGTH 16, PHASE 0.0, "
        f"CLK_DOMAIN {clk_domain}, "
        f"NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, "
        f"RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, "
        f"INSERT_VIP 0"
    )

def clk_param(clk_if_name: str, busif_name: str, rst_sig: str, clk_domain: str) -> str:
    return (
        f"XIL_INTERFACENAME {clk_if_name}, "
        f"ASSOCIATED_BUSIF {busif_name}, "
        f"FREQ_HZ 250000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, "
        f"CLK_DOMAIN {clk_domain}, "
        f"ASSOCIATED_RESET {rst_sig}, "
        f"INSERT_VIP 0"
    )

def rst_param(rst_if_name: str) -> str:
    return f"XIL_INTERFACENAME {rst_if_name}, POLARITY ACTIVE_LOW, INSERT_VIP 0"

def gen_one(i: int, clk_domain: str) -> str:
    n2 = f"{i:02d}"
    bus = f"SAXI_{n2}_RT"
    clk_if = f"ACLK_{n2}_RT"
    rst_if = f"ARST_{n2}_N"
    clk_sig = f"AXI_{n2}_ACLK"
    rst_sig = f"AXI_{n2}_ARESET_N"

    p = []
    # Clock + reset for this AXI interface
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 {clk_if} CLK" *)'
             f' (* X_INTERFACE_MODE = "slave" *)'
             f' (* X_INTERFACE_PARAMETER = "{clk_param(clk_if, bus, rst_sig, clk_domain)}" *)'
             f' input {clk_sig} /* synthesis syn_isclock = 1 */,')

    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 {rst_if} RST" *)'
             f' (* X_INTERFACE_MODE = "slave" *)'
             f' (* X_INTERFACE_PARAMETER = "{rst_param(rst_if)}" *)'
             f' input {rst_sig},')

    # AXI signals (AXI3 subset used by HBM pseudo channels)
    # Put the big X_INTERFACE_PARAMETER on ARADDR like HBM does.
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} ARADDR" *)'
             f' (* X_INTERFACE_MODE = "slave" *)'
             f' (* X_INTERFACE_PARAMETER = "{iface_param(bus, clk_domain)}" *)'
             f' input [32:0]AXI_{n2}_ARADDR,')

    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} ARBURST" *) input [1:0]AXI_{n2}_ARBURST,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} ARID" *)    input [5:0]AXI_{n2}_ARID,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} ARLEN" *)   input [3:0]AXI_{n2}_ARLEN,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} ARSIZE" *)  input [2:0]AXI_{n2}_ARSIZE,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} ARVALID" *) input AXI_{n2}_ARVALID,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} ARREADY" *) output AXI_{n2}_ARREADY,')

    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} AWADDR" *)  input [32:0]AXI_{n2}_AWADDR,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} AWBURST" *) input [1:0]AXI_{n2}_AWBURST,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} AWID" *)    input [5:0]AXI_{n2}_AWID,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} AWLEN" *)   input [3:0]AXI_{n2}_AWLEN,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} AWSIZE" *)  input [2:0]AXI_{n2}_AWSIZE,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} AWVALID" *) input AXI_{n2}_AWVALID,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} AWREADY" *) output AXI_{n2}_AWREADY,')

    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} WDATA" *)   input [255:0]AXI_{n2}_WDATA,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} WSTRB" *)   input [31:0]AXI_{n2}_WSTRB,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} WLAST" *)   input AXI_{n2}_WLAST,')
    p.append(f'  input [31:0]AXI_{n2}_WDATA_PARITY,')  # HBM-specific parity sideband (not aximm-tagged)
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} WVALID" *)  input AXI_{n2}_WVALID,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} WREADY" *)  output AXI_{n2}_WREADY,')

    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} RDATA" *)   output [255:0]AXI_{n2}_RDATA,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} RID" *)     output [5:0]AXI_{n2}_RID,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} RRESP" *)   output [1:0]AXI_{n2}_RRESP,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} RLAST" *)   output AXI_{n2}_RLAST,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} RVALID" *)  output AXI_{n2}_RVALID,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} RREADY" *)  input AXI_{n2}_RREADY,')

    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} BID" *)     output [5:0]AXI_{n2}_BID,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} BRESP" *)   output [1:0]AXI_{n2}_BRESP,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} BVALID" *)  output AXI_{n2}_BVALID,')
    p.append(f'  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 {bus} BREADY" *)  input AXI_{n2}_BREADY,')

    return "\n".join(p)

def main():
    # Use the same clock domain string you saw in the working HBM top
    clk_domain = "xdma_axi_aclk"

    print("// --------------------------------------------------------------------")
    print("// Auto-generated AXI3 (HBM-style) interface metadata for SAXI_00_RT..31")
    print("// Paste into your module port list (or wrapper) and adjust names if needed")
    print("// --------------------------------------------------------------------\n")

    for i in range(32):
        print(f"// -------------------- SAXI_{i:02d}_RT --------------------")
        print(gen_one(i, clk_domain))
        print()

if __name__ == "__main__":
    main()
