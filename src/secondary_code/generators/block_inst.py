#!/usr/bin/env python3

START = 0
END   = 31   # inclusive

PORTS = [
    ("ARADDR",        "signal"),
    ("ARBURST",       "signal"),
    ("ARID",          "signal"),
    ("ARLEN",         "signal"),
    ("ARSIZE",        "signal"),
    ("ARVALID",       "signal"),
    ("ARREADY",       "signal"),
    ("",              ""),
    ("AWADDR",        "signal"),
    ("AWBURST",       "signal"),
    ("AWID",          "signal"),
    ("AWLEN",         "signal"),
    ("AWSIZE",        "signal"),
    ("AWVALID",       "signal"),
    ("AWREADY",       "signal"),
    ("",              ""),
    ("RREADY",        "signal"),
    ("BREADY",        "signal"),
    ("",              ""),
    ("WDATA",         "signal"),
    ("WLAST",         "signal"),
    ("WSTRB",         "signal"),
    ("WDATA_PARITY",  "open"),
    ("WVALID",        "signal"),
    ("WREADY",        "signal"),
    ("",              ""),
    ("RDATA",         "signal"),
    ("RDATA_PARITY",  "open"),
    ("RID",           "signal"),
    ("RLAST",         "signal"),
    ("RRESP",         "signal"),
    ("RVALID",        "signal"),
    ("",              ""),
    ("BID",           "signal"),
    ("BRESP",         "signal"),
    ("BVALID",        "signal"),
]

def axi(n):
    return f"AXI_{n:02d}"

def main():
    for i in range(START, END + 1):
        print("\t\t// --------------------------------------------------")
        print(f"\t\t// {axi(i)}")
        print("\t\t// --------------------------------------------------")

        for name, kind in PORTS:
            if name == "":
                print()
                continue

            lhs = f".{axi(i)}_{name:<22}"
            if kind == "open":
                rhs = "()"
            else:
                rhs = f"({axi(i)}_{name})"

            print(f"\t\t{lhs}{rhs},")

        print()

if __name__ == "__main__":
    main()
