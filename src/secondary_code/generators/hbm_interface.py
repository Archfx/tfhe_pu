#!/usr/bin/env python3

TEMPLATE = r"""
AXI_00_ACLK         : in  std_logic;                                 -- 450 MHz
AXI_00_ARESET_N     : in  std_logic;                                 -- set to 0 to reset. Reset before start of data traffic
-- start addr. must be 128-bit aligned, size must be multiple of 128bit
AXI_00_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0); -- bit 32 selects hbm stack, 31:28 selct AXI port, 27:5 addr, 4:0 unused
AXI_00_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);              -- read burst
AXI_00_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);              -- read addr id
AXI_00_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);              -- burst length
AXI_00_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);              -- burst size
AXI_00_ARVALID      : in  std_logic;
AXI_00_ARREADY      : out std_logic;

AXI_00_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
AXI_00_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
AXI_00_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
AXI_00_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
AXI_00_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
AXI_00_AWVALID      : in  std_logic;
AXI_00_AWREADY      : out std_logic;

AXI_00_RREADY       : in  std_logic;
AXI_00_BREADY       : in  std_logic;

AXI_00_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
AXI_00_WLAST        : in  std_logic;
AXI_00_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
AXI_00_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
AXI_00_WVALID       : in  std_logic;

AXI_00_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
AXI_00_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
AXI_00_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
AXI_00_RLAST        : out std_logic;
AXI_00_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
AXI_00_RVALID       : out std_logic;

AXI_00_WREADY       : out std_logic;

AXI_00_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
AXI_00_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
AXI_00_BVALID       : out std_logic;
"""

def main():
    for axi in range(16, 34):
        axi_str = f"AXI_{axi:02d}_"
        print(f"\n-- ==================================================")
        print(f"-- {axi_str[:-1]}")
        print(f"-- ==================================================")

        for line in TEMPLATE.splitlines():
            if "AXI_00_" in line:
                print(line.replace("AXI_00_", axi_str))
            else:
                print(line)

if __name__ == "__main__":
    main()
