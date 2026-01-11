#!/usr/bin/env python3
"""
Generate VHDL glue for HBM AXI port mux/demux (ports 00..15) with CORRECT widths
based on your HBM port declarations:

ADDR   : std_logic_vector(hbm_addr_width-1 downto 0)
BURST  : std_logic_vector(hbm_burstmode_bit_width-1 downto 0)
ID     : std_logic_vector(hbm_id_bit_width-1 downto 0)
LEN    : std_logic_vector(hbm_burstlen_bit_width-1 downto 0)
SIZE   : std_logic_vector(hbm_burstsize_bit_width-1 downto 0)
DATA   : std_logic_vector(hbm_data_width-1 downto 0)
STRB   : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0)
PARITY : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0)
RESP   : std_logic_vector(hbm_resp_bit_width-1 downto 0)

It outputs 3 sections:
  1) signal declarations (internal HBM wires)
  2) HBM IP port map snippet (connect HBM IP <-> internal wires)
  3) mux inputs into HBM + demux outputs out of HBM for AXI_00..AXI_15

NOTE:
- This is combinational routing. In a correct AXI system, you should LATCH/HOLD the
  select per-transaction (especially if you allow outstanding reads/writes).
"""

FIRST_PORT = 0
LAST_PORT  = 15

# Select signals (assume vectors indexed by port)
HBM_R_SEL = "HBM_R_SELECT"   # used as HBM_R_SELECT(p)
HBM_W_SEL = "HBM_W_SELECT"   # used as HBM_W_SELECT(p)

# TFHE package arrays
I_RPKG = "i_read_pkgs"
O_RPKG = "o_read_pkgs"
I_WPKG = "i_write_pkgs"
O_WPKG = "o_write_pkgs"

# Constants used when TFHE is selected (edit expressions to match your design)
HBM_BURSTMODE_SRC = "std_logic_vector(hbm_burstmode)"
HBM_BURSTSIZE_SRC = "std_logic_vector(hbm_burstsize)"
HBM_WSTRB_SRC     = "std_logic_vector(hbm_strobe_setting)"

# ---------- AXI signal groupings ----------
AR_IN  = ["ARADDR", "ARBURST", "ARID", "ARLEN", "ARSIZE", "ARVALID"]   # into HBM
AR_OUT = ["ARREADY"]                                                  # out of HBM

R_OUT  = ["RDATA_PARITY", "RDATA", "RID", "RLAST", "RRESP", "RVALID"]  # out of HBM
R_IN   = ["RREADY"]                                                   # into HBM

AW_IN  = ["AWADDR", "AWBURST", "AWID", "AWLEN", "AWSIZE", "AWVALID"]   # into HBM
AW_OUT = ["AWREADY"]                                                  # out of HBM

W_IN   = ["WDATA", "WLAST", "WSTRB", "WDATA_PARITY", "WVALID"]         # into HBM
W_OUT  = ["WREADY"]                                                   # out of HBM

B_OUT  = ["BID", "BRESP", "BVALID"]                                    # out of HBM
B_IN   = ["BREADY"]                                                   # into HBM

# ---------- Width/type rules from your HBM port list ----------
def vhdl_type(sig: str) -> str:
    # scalars
    if sig in ("ARVALID", "ARREADY", "AWVALID", "AWREADY", "WVALID", "WREADY",
               "BVALID", "BREADY", "RVALID", "RREADY", "WLAST", "RLAST"):
        return "std_logic"

    # vectors
    if sig in ("ARADDR", "AWADDR"):
        return "std_logic_vector(hbm_addr_width-1 downto 0)"
    if sig in ("ARBURST", "AWBURST"):
        return "std_logic_vector(hbm_burstmode_bit_width-1 downto 0)"
    if sig in ("ARID", "AWID", "RID", "BID"):
        return "std_logic_vector(hbm_id_bit_width-1 downto 0)"
    if sig in ("ARLEN", "AWLEN"):
        return "std_logic_vector(hbm_burstlen_bit_width-1 downto 0)"
    if sig in ("ARSIZE", "AWSIZE"):
        return "std_logic_vector(hbm_burstsize_bit_width-1 downto 0)"
    if sig in ("WDATA", "RDATA"):
        return "std_logic_vector(hbm_data_width-1 downto 0)"
    if sig in ("WSTRB", "WDATA_PARITY", "RDATA_PARITY"):
        return "std_logic_vector(hbm_bytes_per_ps_port-1 downto 0)"
    if sig in ("RRESP", "BRESP"):
        return "std_logic_vector(hbm_resp_bit_width-1 downto 0)"

    raise ValueError(f"Unknown AXI signal for typing: {sig}")

# ---------- TFHE field maps ----------
# Use (p) placeholder then replace to (port_index) when emitting
TFHE_READ_MAP = {
    "ARADDR":  f"std_logic_vector({I_RPKG}(p).araddr)",
    "ARBURST": HBM_BURSTMODE_SRC,
    "ARID":    f"{I_RPKG}(p).arid",
    "ARLEN":   f"{I_RPKG}(p).arlen",
    "ARSIZE":  HBM_BURSTSIZE_SRC,
    "ARVALID": f"{I_RPKG}(p).arvalid",
    "RREADY":  f"{I_RPKG}(p).rready",

    "ARREADY": f"{O_RPKG}(p).arready",
    "RDATA":   f"{O_RPKG}(p).rdata",
    "RDATA_PARITY": f"{O_RPKG}(p).rdata_parity",
    "RID":     f"{O_RPKG}(p).rid",
    "RLAST":   f"{O_RPKG}(p).rlast",
    "RRESP":   f"{O_RPKG}(p).rresp",
    "RVALID":  f"{O_RPKG}(p).rvalid",
}

TFHE_WRITE_MAP = {
    "AWADDR":  f"std_logic_vector({I_WPKG}(p).awaddr)",
    "AWBURST": HBM_BURSTMODE_SRC,
    "AWID":    f"{I_WPKG}(p).awid",
    "AWLEN":   f"{I_WPKG}(p).awlen",
    "AWSIZE":  HBM_BURSTSIZE_SRC,
    "AWVALID": f"{I_WPKG}(p).awvalid",

    "WDATA":   f"{I_WPKG}(p).wdata",
    "WLAST":   f"{I_WPKG}(p).wlast",
    "WSTRB":   HBM_WSTRB_SRC,
    "WDATA_PARITY": f"{I_WPKG}(p).wdata_parity",
    "WVALID":  f"{I_WPKG}(p).wvalid",

    "BREADY":  f"{I_WPKG}(p).bready",

    "AWREADY": f"{O_WPKG}(p).awready",
    "WREADY":  f"{O_WPKG}(p).wready",
    "BID":     f"{O_WPKG}(p).bid",
    "BRESP":   f"{O_WPKG}(p).bresp",
    "BVALID":  f"{O_WPKG}(p).bvalid",
}

def p2(idx: int) -> str:
    return f"{idx:02d}"

def hbm_sig(port: str, sig: str) -> str:
    return f"hbm_{port}_{sig.lower()}"

def hbm_port(port: str, sig: str) -> str:
    return f"AXI_{port}_{sig}"

def host_sig(port: str, sig: str) -> str:
    # Host-side signals (external) are assumed to have same names as HBM ports
    return f"AXI_{port}_{sig}"

def sel_read(idx: int) -> str:
	return f"HBM_RW_SELECT(1)"
    # return f"{HBM_R_SEL}({idx})"

def sel_write(idx: int) -> str:
	return f"HBM_RW_SELECT(0)"
    # return f"{HBM_W_SEL}({idx})"

def default_for(sig: str) -> str:
    t = vhdl_type(sig)
    if t == "std_logic":
        return "'0'"
    return "(others => '0')"

def emit_header(title: str) -> str:
    return (
        "\n-- ==================================================\n"
        f"-- {title}\n"
        "-- ==================================================\n"
    )

def emit_signal_decls() -> str:
    out = [emit_header("INTERNAL HBM SIGNAL DECLARATIONS (AXI_00..AXI_15)")]
    for p in range(FIRST_PORT, LAST_PORT + 1):
        port = p2(p)
        all_sigs = AR_IN + AR_OUT + R_IN + R_OUT + AW_IN + AW_OUT + W_IN + W_OUT + B_IN + B_OUT
        for sig in all_sigs:
            out.append(f"signal {hbm_sig(port, sig)} : {vhdl_type(sig)};")
        out.append("")
    return "\n".join(out)

def emit_hbm_portmap() -> str:
    out = [emit_header("HBM IP PORT MAP (CONNECT INTERNAL SIGNALS ONLY)")]
    out.append("-- In your HBM IP instantiation, connect like this (snippet):")
    for p in range(FIRST_PORT, LAST_PORT + 1):
        port = p2(p)
        out.append(f"-- ---- AXI_{port} ----")
        for sig in (AR_IN + AR_OUT + R_IN + R_OUT + AW_IN + AW_OUT + W_IN + W_OUT + B_IN + B_OUT):
            out.append(f"{hbm_port(port, sig):<18} => {hbm_sig(port, sig)},")
        out.append("")
    out.append("-- Remove trailing comma on the final association in your real port map.")
    return "\n".join(out)

def emit_mux_demux() -> str:
    out = [emit_header("MUX INPUTS INTO HBM + DEMUX OUTPUTS OUT OF HBM")]
    out.append("-- Convention: select='0' => HOST owns that channel, select='1' => TFHE owns that channel\n")
    for p in range(FIRST_PORT, LAST_PORT + 1):
        port = p2(p)
        out.append(f"-- -------------------- AXI_{port} --------------------")

        # READ: mux inputs into HBM
        for sig in AR_IN:
            tfhe_expr = TFHE_READ_MAP[sig].replace("(p)", f"({p})")
            out.append(
                f"{hbm_sig(port, sig)} <= {host_sig(port, sig)} when {sel_read(p)}='0' else {tfhe_expr};"
            )
        sig = "RREADY"
        tfhe_expr = TFHE_READ_MAP[sig].replace("(p)", f"({p})")
        out.append(
            f"{hbm_sig(port, sig)} <= {host_sig(port, sig)} when {sel_read(p)}='0' else {tfhe_expr};"
        )
        out.append("")

        # READ: demux outputs from HBM
        out.append(
            f"{host_sig(port, 'ARREADY')} <= {hbm_sig(port, 'ARREADY')} when {sel_read(p)}='0' else '0';"
        )
        out.append(
            f"{O_RPKG}({p}).arready <= {hbm_sig(port, 'ARREADY')} when {sel_read(p)}='1' else '0';"
        )
        for sig in R_OUT:
            out.append(
                f"{host_sig(port, sig)} <= {hbm_sig(port, sig)} when {sel_read(p)}='0' else {default_for(sig)};"
            )
            out.append(
                f"{O_RPKG}({p}).{sig.lower()} <= {hbm_sig(port, sig)} when {sel_read(p)}='1' else {default_for(sig)};"
            )
        out.append("")

        # WRITE: mux inputs into HBM
        for sig in AW_IN:
            tfhe_expr = TFHE_WRITE_MAP[sig].replace("(p)", f"({p})")
            out.append(
                f"{hbm_sig(port, sig)} <= {host_sig(port, sig)} when {sel_write(p)}='0' else {tfhe_expr};"
            )
        for sig in W_IN:
            tfhe_expr = TFHE_WRITE_MAP[sig].replace("(p)", f"({p})")
            out.append(
                f"{hbm_sig(port, sig)} <= {host_sig(port, sig)} when {sel_write(p)}='0' else {tfhe_expr};"
            )
        sig = "BREADY"
        tfhe_expr = TFHE_WRITE_MAP[sig].replace("(p)", f"({p})")
        out.append(
            f"{hbm_sig(port, sig)} <= {host_sig(port, sig)} when {sel_write(p)}='0' else {tfhe_expr};"
        )
        out.append("")

        # WRITE: demux outputs from HBM
        out.append(
            f"{host_sig(port, 'AWREADY')} <= {hbm_sig(port, 'AWREADY')} when {sel_write(p)}='0' else '0';"
        )
        out.append(
            f"{O_WPKG}({p}).awready <= {hbm_sig(port, 'AWREADY')} when {sel_write(p)}='1' else '0';"
        )
        out.append(
            f"{host_sig(port, 'WREADY')} <= {hbm_sig(port, 'WREADY')} when {sel_write(p)}='0' else '0';"
        )
        out.append(
            f"{O_WPKG}({p}).wready <= {hbm_sig(port, 'WREADY')} when {sel_write(p)}='1' else '0';"
        )
        for sig in B_OUT:
            out.append(
                f"{host_sig(port, sig)} <= {hbm_sig(port, sig)} when {sel_write(p)}='0' else {default_for(sig)};"
            )
            out.append(
                f"{O_WPKG}({p}).{sig.lower()} <= {hbm_sig(port, sig)} when {sel_write(p)}='1' else {default_for(sig)};"
            )

        out.append("\n")
    return "\n".join(out)

def main():
    print(emit_signal_decls())
    print(emit_hbm_portmap())
    print(emit_mux_demux())

if __name__ == "__main__":
    main()
