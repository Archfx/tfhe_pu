#!/usr/bin/env python3
"""
Generate VHDL "HOST-only direct connect" wiring for AXI_00..AXI_15.

This REPLACES your current:
  -- MUX INPUTS INTO HBM + DEMUX OUTPUTS OUT OF HBM

with a simple direct connection:
  hbm_##_* <= AXI_##_*   for all HBM inputs
  AXI_##_* <= hbm_##_*   for all HBM outputs

It also drives the TFHE pkg outputs to safe zeros (optional, but avoids undriven nets).

Edit:
  FIRST_PORT/LAST_PORT if needed.
"""

FIRST_PORT = 0
LAST_PORT  = 15

# If you want to also force TFHE outputs low (recommended for a clean test)
DRIVE_TFHE_DEFAULTS = True

O_RPKG = "o_read_pkgs"
O_WPKG = "o_write_pkgs"

# HBM slave inputs (driven by host master)
AR_IN = ["ARADDR", "ARBURST", "ARID", "ARLEN", "ARSIZE", "ARVALID", "RREADY"]
AW_W_B_IN = ["AWADDR", "AWBURST", "AWID", "AWLEN", "AWSIZE", "AWVALID",
            "WDATA", "WLAST", "WSTRB", "WDATA_PARITY", "WVALID",
            "BREADY"]

# HBM slave outputs (observed by host master)
AR_OUT = ["ARREADY"]
R_OUT  = ["RDATA_PARITY", "RDATA", "RID", "RLAST", "RRESP", "RVALID"]
W_OUT  = ["AWREADY", "WREADY"]
B_OUT  = ["BID", "BRESP", "BVALID"]

def p2(i: int) -> str:
    return f"{i:02d}"

def host(port: str, sig: str) -> str:
    return f"AXI_{port}_{sig}"

def hbm(port: str, sig: str) -> str:
    return f"hbm_{port}_{sig.lower()}"

def default_for_sig(sig: str) -> str:
    # Scalars
    if sig in ("ARVALID","ARREADY","AWVALID","AWREADY","WVALID","WREADY",
               "BVALID","BREADY","RVALID","RREADY","WLAST","RLAST"):
        return "'0'"
    # Vectors (width inferred by VHDL from LHS)
    return "(others => '0')"

def tfhe_read_fields():
    # Match your field names in the snippet you posted
    return ["arready", "rdata_parity", "rdata", "rid", "rlast", "rresp", "rvalid"]

def tfhe_write_fields():
    return ["awready", "wready", "bid", "bresp", "bvalid"]

def main():
    lines = []
    lines.append("-- ==================================================")
    lines.append("-- HOST-ONLY DIRECT CONNECT (HBM <-> HOST), TFHE DISABLED")
    lines.append("-- ==================================================")
    lines.append("")

    for p in range(FIRST_PORT, LAST_PORT + 1):
        port = p2(p)
        lines.append(f"-- -------------------- AXI_{port} --------------------")

        # Drive HBM inputs from host
        for sig in AR_IN:
            lines.append(f"{hbm(port, sig)} <= {host(port, sig)};")
        for sig in AW_W_B_IN:
            lines.append(f"{hbm(port, sig)} <= {host(port, sig)};")
        lines.append("")

        # Drive host outputs from HBM outputs
        for sig in AR_OUT:
            lines.append(f"{host(port, sig)} <= {hbm(port, sig)};")
        for sig in R_OUT:
            lines.append(f"{host(port, sig)} <= {hbm(port, sig)};")
        for sig in W_OUT:
            lines.append(f"{host(port, sig)} <= {hbm(port, sig)};")
        for sig in B_OUT:
            lines.append(f"{host(port, sig)} <= {hbm(port, sig)};")
        lines.append("")

        # Optionally force TFHE outputs to defaults so nothing is left floating/unknown
        if DRIVE_TFHE_DEFAULTS:
            for f in tfhe_read_fields():
                lines.append(f"{O_RPKG}({p}).{f} <= {default_for_sig(f.upper())};")
            for f in tfhe_write_fields():
                lines.append(f"{O_WPKG}({p}).{f} <= {default_for_sig(f.upper())};")
            lines.append("")

        lines.append("")

    print("\n".join(lines))

if __name__ == "__main__":
    main()
