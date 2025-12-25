#!/usr/bin/env python3

# --------------------------------------------------
# Configuration
# --------------------------------------------------
SRC_START = 0      # AXI_00
DST_START = 16     # AXI_16
COUNT     = 16      # generate AXI_00..01 → AXI_16..17 (change as needed)

# AXI signal order template
SIGNALS = [
    "ARADDR", "ARBURST", "ARID", "ARLEN", "ARSIZE", "ARVALID", "ARREADY",
    "",
    "AWADDR", "AWBURST", "AWID", "AWLEN", "AWSIZE", "AWVALID", "AWREADY",
    "",
    "RREADY", "BREADY",
    "WDATA", "WLAST", "WSTRB", "WDATA_PARITY", "WVALID", "WREADY",
    "",
    "RDATA", "RDATA_PARITY", "RID", "RLAST", "RRESP", "RVALID",
    "",
    "BID", "BRESP", "BVALID",
]

OPEN_SIGNALS = {
    "WDATA_PARITY",
    "RDATA_PARITY",
}

def axi(n):
    return f"AXI_{n:02d}"

def main():
    for i in range(COUNT):
        src = SRC_START + i
        dst = DST_START + i

        print("\t\t\t-- --------------------------------------------------")
        print(f"\t\t\t-- {axi(src)}")
        print("\t\t\t-- --------------------------------------------------")

        for sig in SIGNALS:
            if sig == "":
                print()
                continue

            lhs = f"{axi(src)}_{sig}"
            if sig in OPEN_SIGNALS:
                rhs = "open"
            else:
                rhs = f"{axi(dst)}_{sig}"

            print(f"\t\t\t{lhs:<22} => {rhs},")

        print()

if __name__ == "__main__":
    main()
