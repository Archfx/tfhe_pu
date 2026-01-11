# NUM_PORTS = 32

# for i in range(NUM_PORTS):
#     idx = f"{i:02d}"

#     print(f"// --------------------------------------------------")
#     print(f"// AXI_{idx} sideband signals")
#     print(f"// --------------------------------------------------")

#     # Read address channel
#     print(f"input  wire [2:0] AXI_{idx}_ARPROT,")
#     print(f"input  wire [3:0] AXI_{idx}_ARCACHE,")
#     print(f"input  wire       AXI_{idx}_ARLOCK,")
#     print(f"input  wire [3:0] AXI_{idx}_ARQOS,")

#     # Write address channel
#     print(f"input  wire [2:0] AXI_{idx}_AWPROT,")
#     print(f"input  wire [3:0] AXI_{idx}_AWCACHE,")
#     print(f"input  wire       AXI_{idx}_AWLOCK,")
#     print(f"input  wire [3:0] AXI_{idx}_AWQOS,")

#     print()


NUM_PORTS = 32

for i in range(NUM_PORTS):
    idx = f"{i:02d}"

    print(f"// AXI_{idx} sideband unused tie-offs")
    print(f"wire _unused_axi_{idx}_arprot  = &AXI_{idx}_ARPROT;")
    print(f"wire _unused_axi_{idx}_arcache = &AXI_{idx}_ARCACHE;")
    print(f"wire _unused_axi_{idx}_arlock  = AXI_{idx}_ARLOCK;")
    print(f"wire _unused_axi_{idx}_arqos   = &AXI_{idx}_ARQOS;")
    print(f"wire _unused_axi_{idx}_awprot  = &AXI_{idx}_AWPROT;")
    print(f"wire _unused_axi_{idx}_awcache = &AXI_{idx}_AWCACHE;")
    print(f"wire _unused_axi_{idx}_awlock  = AXI_{idx}_AWLOCK;")
    print(f"wire _unused_axi_{idx}_awqos   = &AXI_{idx}_AWQOS;")
    print()
