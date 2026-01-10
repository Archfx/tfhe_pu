#!/usr/bin/env python3
"""
Generate IP-XACT <spirit:memoryMaps> entries for AXI_00..AXI_31
with non-overlapping 256MB windows.

Base step: 0x1000_0000 (256MB)
Range:     268435456   (256MB)
Width:     256         (bits)
Usage:     memory
"""

NUM_PORTS = 32
WINDOW_SIZE_BYTES = 256 * 1024 * 1024  # 256MB
WIDTH_BITS = 256

def hex0(x: int) -> str:
    return f"0x{x:X}"

def gen_one(i: int) -> str:
    base = i * WINDOW_SIZE_BYTES
    axi = f"AXI_{i:02d}"
    mem = f"HBM_MEM_{i:02d}"
    return f"""    <spirit:memoryMap>
      <spirit:name>{axi}</spirit:name>
      <spirit:displayName>{axi}</spirit:displayName>
      <spirit:addressBlock>
        <spirit:name>{mem}</spirit:name>
        <spirit:displayName>memory</spirit:displayName>
        <spirit:baseAddress spirit:format="bitString" spirit:bitStringLength="1">{hex0(base)}</spirit:baseAddress>
        <spirit:range spirit:format="long" spirit:minimum="4096" spirit:rangeType="long">{WINDOW_SIZE_BYTES}</spirit:range>
        <spirit:width spirit:format="long">{WIDTH_BITS}</spirit:width>
        <spirit:usage>memory</spirit:usage>
      </spirit:addressBlock>
    </spirit:memoryMap>"""

def main():
    print("<spirit:memoryMaps>")
    for i in range(NUM_PORTS):
        print(gen_one(i))
    print("</spirit:memoryMaps>")

if __name__ == "__main__":
    main()
