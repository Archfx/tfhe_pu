library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

library work;
	use work.ip_cores_constants.all;
	use work.processor_utils.all;
	use work.datatypes_utils.all;
	use work.math_utils.all;
	use work.tfhe_constants.all;

--                  ┌───────────────┐
-- AXI from BD ───> │               │
--                  │   AXI MUX     ├──> hbm_1
-- Packages ──────> │               │
--                  └──────^────────┘
--                         │
--                   HBM_RW_SELECT


entity hbm_w_1 is
  port (

    -- AXI select
    HBM_RW_SELECT     : in  std_logic_vector(1 downto 0);

    --- Global signals
	-- TFHE_CLK	   : in  std_logic;




    ------------------------------------------------------------------
    -- External AXI master (to the crossbar)
    ------------------------------------------------------------------
    HBM_REF_CLK_0       : in  std_logic;                                 -- 100 MHz, drives a PLL. Must be sourced from a MMCM/BUFG

	AXI_00_ACLK         : in  std_logic;                                 -- 450 MHz
	AXI_00_ARESET_N     : in  std_logic;                                 -- set to 0 to reset. Reset before start of data traffic
	-- start addr. must be 128-bit aligned, size must be multiple of 128bit
	AXI_00_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0); -- bit 32 selects hbm stack, 31:28 selct AXI port, 27:5 addr, 4:0 unused
	AXI_00_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);              -- read burst: use '01' # 00fixed(not supported), 01incr, 11wrap(like incr but wraps at the end, slower)
	AXI_00_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);              -- read addr. id tag (we have no need for this if the outputs are in the correct order, otherwise need ping-pong-buffer)
	AXI_00_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);              -- read burst length --> constant '1111'
	AXI_00_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);              -- read burst size, only 256-bit size supported (b'101')
	AXI_00_ARVALID      : in  std_logic;                                 -- read addr valid --> constant 1
	AXI_00_ARREADY      : out std_logic;                                 -- "read address ready" --> can accept a new read address
	-- same as for read
	AXI_00_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_00_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_00_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_00_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_00_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_00_AWVALID      : in  std_logic;
	AXI_00_AWREADY      : out std_logic;                                 -- "write address ready" --> can accept a new write address
	--
	AXI_00_RREADY       : in  std_logic;                                 --"read ready" signals that we read the input so the next one can come? Must be high to transmit the input data, set to 1
	AXI_00_BREADY       : in  std_logic;                                 --"response ready" --> read response, can accept new response
	AXI_00_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);            -- data to write
	AXI_00_WLAST        : in  std_logic;                                 -- shows that this was the last value that was written
	AXI_00_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);             -- write strobe --> one bit per write byte on the bus to tell that it should be written --> set all to 1.
	AXI_00_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);             -- why would I need that? Is data loss expeced?
	AXI_00_WVALID       : in  std_logic;
	AXI_00_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);             -- no need?
	AXI_00_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);            -- read data
	AXI_00_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_00_RLAST        : out std_logic;                                 -- shows that this was the last value that was read
	AXI_00_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);              -- read response --> which are possible?
	AXI_00_RVALID       : out std_logic;                                 -- signals output is there
	AXI_00_WREADY       : out std_logic;                                 -- signals that the values are now stored
	--
	AXI_00_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);              --"response ID tag" for AXI_00_BRESP
	AXI_00_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);              --Write response: 00 - OK, 01 - exclusive access OK, 10 - slave error, 11 decode error
	AXI_00_BVALID       : out std_logic;                                 --"Write response ready"

	AXI_01_ACLK         : in  std_logic;
	AXI_01_ARESET_N     : in  std_logic;
	AXI_01_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_01_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_01_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_01_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_01_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_01_ARVALID      : in  std_logic;
	AXI_01_ARREADY      : out std_logic;
	AXI_01_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_01_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_01_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_01_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_01_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_01_AWVALID      : in  std_logic;
	AXI_01_AWREADY      : out std_logic;
	AXI_01_RREADY       : in  std_logic;
	AXI_01_BREADY       : in  std_logic;
	AXI_01_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_01_WLAST        : in  std_logic;
	AXI_01_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_01_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_01_WVALID       : in  std_logic;
	AXI_01_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_01_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_01_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_01_RLAST        : out std_logic;
	AXI_01_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_01_RVALID       : out std_logic;
	AXI_01_WREADY       : out std_logic;
	AXI_01_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_01_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_01_BVALID       : out std_logic;

	AXI_02_ACLK         : in  std_logic;
	AXI_02_ARESET_N     : in  std_logic;
	AXI_02_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_02_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_02_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_02_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_02_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_02_ARVALID      : in  std_logic;
	AXI_02_ARREADY      : out std_logic;
	AXI_02_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_02_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_02_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_02_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_02_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_02_AWVALID      : in  std_logic;
	AXI_02_AWREADY      : out std_logic;
	AXI_02_RREADY       : in  std_logic;
	AXI_02_BREADY       : in  std_logic;
	AXI_02_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_02_WLAST        : in  std_logic;
	AXI_02_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_02_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_02_WVALID       : in  std_logic;
	AXI_02_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_02_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_02_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_02_RLAST        : out std_logic;
	AXI_02_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_02_RVALID       : out std_logic;
	AXI_02_WREADY       : out std_logic;
	AXI_02_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_02_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_02_BVALID       : out std_logic;

	AXI_03_ACLK         : in  std_logic;
	AXI_03_ARESET_N     : in  std_logic;
	AXI_03_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_03_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_03_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_03_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_03_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_03_ARVALID      : in  std_logic;
	AXI_03_ARREADY      : out std_logic;
	AXI_03_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_03_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_03_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_03_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_03_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_03_AWVALID      : in  std_logic;
	AXI_03_AWREADY      : out std_logic;
	AXI_03_RREADY       : in  std_logic;
	AXI_03_BREADY       : in  std_logic;
	AXI_03_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_03_WLAST        : in  std_logic;
	AXI_03_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_03_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_03_WVALID       : in  std_logic;
	AXI_03_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_03_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_03_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_03_RLAST        : out std_logic;
	AXI_03_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_03_RVALID       : out std_logic;
	AXI_03_WREADY       : out std_logic;
	AXI_03_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_03_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_03_BVALID       : out std_logic;

	AXI_04_ACLK         : in  std_logic;
	AXI_04_ARESET_N     : in  std_logic;
	AXI_04_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_04_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_04_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_04_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_04_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_04_ARVALID      : in  std_logic;
	AXI_04_ARREADY      : out std_logic;
	AXI_04_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_04_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_04_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_04_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_04_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_04_AWVALID      : in  std_logic;
	AXI_04_AWREADY      : out std_logic;
	AXI_04_RREADY       : in  std_logic;
	AXI_04_BREADY       : in  std_logic;
	AXI_04_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_04_WLAST        : in  std_logic;
	AXI_04_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_04_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_04_WVALID       : in  std_logic;
	AXI_04_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_04_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_04_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_04_RLAST        : out std_logic;
	AXI_04_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_04_RVALID       : out std_logic;
	AXI_04_WREADY       : out std_logic;
	AXI_04_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_04_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_04_BVALID       : out std_logic;

	AXI_05_ACLK         : in  std_logic;
	AXI_05_ARESET_N     : in  std_logic;
	AXI_05_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_05_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_05_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_05_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_05_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_05_ARVALID      : in  std_logic;
	AXI_05_ARREADY      : out std_logic;
	AXI_05_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_05_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_05_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_05_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_05_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_05_AWVALID      : in  std_logic;
	AXI_05_AWREADY      : out std_logic;
	AXI_05_RREADY       : in  std_logic;
	AXI_05_BREADY       : in  std_logic;
	AXI_05_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_05_WLAST        : in  std_logic;
	AXI_05_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_05_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_05_WVALID       : in  std_logic;
	AXI_05_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_05_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_05_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_05_RLAST        : out std_logic;
	AXI_05_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_05_RVALID       : out std_logic;
	AXI_05_WREADY       : out std_logic;
	AXI_05_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_05_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_05_BVALID       : out std_logic;

	AXI_06_ACLK         : in  std_logic;
	AXI_06_ARESET_N     : in  std_logic;
	AXI_06_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_06_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_06_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_06_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_06_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_06_ARVALID      : in  std_logic;
	AXI_06_ARREADY      : out std_logic;
	AXI_06_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_06_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_06_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_06_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_06_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_06_AWVALID      : in  std_logic;
	AXI_06_AWREADY      : out std_logic;
	AXI_06_RREADY       : in  std_logic;
	AXI_06_BREADY       : in  std_logic;
	AXI_06_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_06_WLAST        : in  std_logic;
	AXI_06_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_06_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_06_WVALID       : in  std_logic;
	AXI_06_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_06_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_06_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_06_RLAST        : out std_logic;
	AXI_06_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_06_RVALID       : out std_logic;
	AXI_06_WREADY       : out std_logic;
	AXI_06_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_06_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_06_BVALID       : out std_logic;

	AXI_07_ACLK         : in  std_logic;
	AXI_07_ARESET_N     : in  std_logic;
	AXI_07_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_07_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_07_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_07_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_07_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_07_ARVALID      : in  std_logic;
	AXI_07_ARREADY      : out std_logic;
	AXI_07_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_07_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_07_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_07_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_07_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_07_AWVALID      : in  std_logic;
	AXI_07_AWREADY      : out std_logic;
	AXI_07_RREADY       : in  std_logic;
	AXI_07_BREADY       : in  std_logic;
	AXI_07_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_07_WLAST        : in  std_logic;
	AXI_07_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_07_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_07_WVALID       : in  std_logic;
	AXI_07_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_07_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_07_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_07_RLAST        : out std_logic;
	AXI_07_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_07_RVALID       : out std_logic;
	AXI_07_WREADY       : out std_logic;
	AXI_07_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_07_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_07_BVALID       : out std_logic;

	AXI_08_ACLK         : in  std_logic;
	AXI_08_ARESET_N     : in  std_logic;
	AXI_08_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_08_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_08_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_08_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_08_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_08_ARVALID      : in  std_logic;
	AXI_08_ARREADY      : out std_logic;
	AXI_08_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_08_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_08_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_08_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_08_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_08_AWVALID      : in  std_logic;
	AXI_08_AWREADY      : out std_logic;
	AXI_08_RREADY       : in  std_logic;
	AXI_08_BREADY       : in  std_logic;
	AXI_08_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_08_WLAST        : in  std_logic;
	AXI_08_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_08_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_08_WVALID       : in  std_logic;
	AXI_08_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_08_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_08_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_08_RLAST        : out std_logic;
	AXI_08_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_08_RVALID       : out std_logic;
	AXI_08_WREADY       : out std_logic;
	AXI_08_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_08_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_08_BVALID       : out std_logic;

	AXI_09_ACLK         : in  std_logic;
	AXI_09_ARESET_N     : in  std_logic;
	AXI_09_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_09_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_09_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_09_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_09_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_09_ARVALID      : in  std_logic;
	AXI_09_ARREADY      : out std_logic;
	AXI_09_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_09_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_09_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_09_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_09_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_09_AWVALID      : in  std_logic;
	AXI_09_AWREADY      : out std_logic;
	AXI_09_RREADY       : in  std_logic;
	AXI_09_BREADY       : in  std_logic;
	AXI_09_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_09_WLAST        : in  std_logic;
	AXI_09_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_09_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_09_WVALID       : in  std_logic;
	AXI_09_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_09_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_09_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_09_RLAST        : out std_logic;
	AXI_09_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_09_RVALID       : out std_logic;
	AXI_09_WREADY       : out std_logic;
	AXI_09_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_09_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_09_BVALID       : out std_logic;

	AXI_10_ACLK         : in  std_logic;
	AXI_10_ARESET_N     : in  std_logic;
	AXI_10_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_10_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_10_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_10_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_10_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_10_ARVALID      : in  std_logic;
	AXI_10_ARREADY      : out std_logic;
	AXI_10_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_10_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_10_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_10_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_10_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_10_AWVALID      : in  std_logic;
	AXI_10_AWREADY      : out std_logic;
	AXI_10_RREADY       : in  std_logic;
	AXI_10_BREADY       : in  std_logic;
	AXI_10_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_10_WLAST        : in  std_logic;
	AXI_10_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_10_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_10_WVALID       : in  std_logic;
	AXI_10_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_10_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_10_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_10_RLAST        : out std_logic;
	AXI_10_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_10_RVALID       : out std_logic;
	AXI_10_WREADY       : out std_logic;
	AXI_10_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_10_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_10_BVALID       : out std_logic;

	AXI_11_ACLK         : in  std_logic;
	AXI_11_ARESET_N     : in  std_logic;
	AXI_11_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_11_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_11_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_11_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_11_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_11_ARVALID      : in  std_logic;
	AXI_11_ARREADY      : out std_logic;
	AXI_11_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_11_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_11_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_11_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_11_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_11_AWVALID      : in  std_logic;
	AXI_11_AWREADY      : out std_logic;
	AXI_11_RREADY       : in  std_logic;
	AXI_11_BREADY       : in  std_logic;
	AXI_11_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_11_WLAST        : in  std_logic;
	AXI_11_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_11_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_11_WVALID       : in  std_logic;
	AXI_11_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_11_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_11_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_11_RLAST        : out std_logic;
	AXI_11_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_11_RVALID       : out std_logic;
	AXI_11_WREADY       : out std_logic;
	AXI_11_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_11_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_11_BVALID       : out std_logic;

	AXI_12_ACLK         : in  std_logic;
	AXI_12_ARESET_N     : in  std_logic;
	AXI_12_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_12_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_12_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_12_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_12_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_12_ARVALID      : in  std_logic;
	AXI_12_ARREADY      : out std_logic;
	AXI_12_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_12_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_12_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_12_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_12_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_12_AWVALID      : in  std_logic;
	AXI_12_AWREADY      : out std_logic;
	AXI_12_RREADY       : in  std_logic;
	AXI_12_BREADY       : in  std_logic;
	AXI_12_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_12_WLAST        : in  std_logic;
	AXI_12_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_12_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_12_WVALID       : in  std_logic;
	AXI_12_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_12_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_12_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_12_RLAST        : out std_logic;
	AXI_12_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_12_RVALID       : out std_logic;
	AXI_12_WREADY       : out std_logic;
	AXI_12_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_12_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_12_BVALID       : out std_logic;

	AXI_13_ACLK         : in  std_logic;
	AXI_13_ARESET_N     : in  std_logic;
	AXI_13_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_13_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_13_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_13_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_13_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_13_ARVALID      : in  std_logic;
	AXI_13_ARREADY      : out std_logic;
	AXI_13_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_13_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_13_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_13_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_13_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_13_AWVALID      : in  std_logic;
	AXI_13_AWREADY      : out std_logic;
	AXI_13_RREADY       : in  std_logic;
	AXI_13_BREADY       : in  std_logic;
	AXI_13_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_13_WLAST        : in  std_logic;
	AXI_13_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_13_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_13_WVALID       : in  std_logic;
	AXI_13_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_13_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_13_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_13_RLAST        : out std_logic;
	AXI_13_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_13_RVALID       : out std_logic;
	AXI_13_WREADY       : out std_logic;
	AXI_13_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_13_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_13_BVALID       : out std_logic;

	AXI_14_ACLK         : in  std_logic;
	AXI_14_ARESET_N     : in  std_logic;
	AXI_14_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_14_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_14_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_14_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_14_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_14_ARVALID      : in  std_logic;
	AXI_14_ARREADY      : out std_logic;
	AXI_14_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_14_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_14_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_14_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_14_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_14_AWVALID      : in  std_logic;
	AXI_14_AWREADY      : out std_logic;
	AXI_14_RREADY       : in  std_logic;
	AXI_14_BREADY       : in  std_logic;
	AXI_14_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_14_WLAST        : in  std_logic;
	AXI_14_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_14_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_14_WVALID       : in  std_logic;
	AXI_14_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_14_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_14_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_14_RLAST        : out std_logic;
	AXI_14_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_14_RVALID       : out std_logic;
	AXI_14_WREADY       : out std_logic;
	AXI_14_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_14_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_14_BVALID       : out std_logic;

	AXI_15_ACLK         : in  std_logic;
	AXI_15_ARESET_N     : in  std_logic;
	AXI_15_ARADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_15_ARBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_15_ARID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_15_ARLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_15_ARSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_15_ARVALID      : in  std_logic;
	AXI_15_ARREADY      : out std_logic;
	AXI_15_AWADDR       : in  std_logic_vector(hbm_addr_width-1 downto 0);
	AXI_15_AWBURST      : in  std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	AXI_15_AWID         : in  std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_15_AWLEN        : in  std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	AXI_15_AWSIZE       : in  std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	AXI_15_AWVALID      : in  std_logic;
	AXI_15_AWREADY      : out std_logic;
	AXI_15_RREADY       : in  std_logic;
	AXI_15_BREADY       : in  std_logic;
	AXI_15_WDATA        : in  std_logic_vector(hbm_data_width-1 downto 0);
	AXI_15_WLAST        : in  std_logic;
	AXI_15_WSTRB        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_15_WDATA_PARITY : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_15_WVALID       : in  std_logic;
	AXI_15_RDATA_PARITY : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	AXI_15_RDATA        : out std_logic_vector(hbm_data_width-1 downto 0);
	AXI_15_RID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_15_RLAST        : out std_logic;
	AXI_15_RRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_15_RVALID       : out std_logic;
	AXI_15_WREADY       : out std_logic;
	AXI_15_BID          : out std_logic_vector(hbm_id_bit_width-1 downto 0);
	AXI_15_BRESP        : out std_logic_vector(hbm_resp_bit_width-1 downto 0);
	AXI_15_BVALID       : out std_logic;



	-- APB configures the HBM during startup
	APB_0_PCLK          : in  std_logic;                                 -- "APB port clock", must match with apb interface clock which is between 50 MHz and 100 MHz
	APB_0_PRESET_N      : in  std_logic;

	-- APB_0_PWDATA        : in  std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	-- APB_0_PADDR         : in  std_logic_vector(21 downto 0);
	-- APB_0_PENABLE       : in  std_logic;
	-- APB_0_PSEL          : in  std_logic;
	-- APB_0_PWRITE        : in  std_logic;
	-- APB_0_PRDATA        : out std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	-- APB_0_PREADY        : out std_logic;
	-- APB_0_PSLVERR       : out std_logic;
	apb_complete_0      : out std_logic;                                 -- indicates that the initial configuration is complete
	DRAM_0_STAT_CATTRIP : out std_logic;                                 -- catastrophiccally high temperatures, shutdown memory access!
	DRAM_0_STAT_TEMP    : out std_logic_vector(6 downto 0);

	i_write_pkgs         : in hbm_ps_in_write_pkg_arr(0 to hbm_stack_num_ps_ports - 1);
	i_read_pkgs          : in hbm_ps_in_read_pkg_arr(0 to hbm_stack_num_ps_ports - 1);
	o_write_pkgs         : out hbm_ps_out_write_pkg_arr(0 to hbm_stack_num_ps_ports - 1);
	o_read_pkgs          : out hbm_ps_out_read_pkg_arr(0 to hbm_stack_num_ps_ports - 1);
	o_initial_init_ready : out std_ulogic

  );
end entity;

architecture rtl of hbm_w_1 is

	signal HBM_R_SELECT        : std_ulogic;
	signal HBM_W_SELECT        : std_ulogic;
	signal TFHE_RESET_N : std_ulogic;


	-- ==================================================
	-- INTERNAL HBM SIGNAL DECLARATIONS (AXI_00..AXI_15)
	-- ==================================================

	signal hbm_00_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_00_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_00_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_00_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_00_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_00_arvalid : std_logic;
	signal hbm_00_arready : std_logic;
	signal hbm_00_rready : std_logic;
	signal hbm_00_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_00_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_00_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_00_rlast : std_logic;
	signal hbm_00_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_00_rvalid : std_logic;
	signal hbm_00_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_00_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_00_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_00_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_00_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_00_awvalid : std_logic;
	signal hbm_00_awready : std_logic;
	signal hbm_00_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_00_wlast : std_logic;
	signal hbm_00_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_00_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_00_wvalid : std_logic;
	signal hbm_00_wready : std_logic;
	signal hbm_00_bready : std_logic;
	signal hbm_00_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_00_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_00_bvalid : std_logic;

	signal hbm_01_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_01_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_01_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_01_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_01_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_01_arvalid : std_logic;
	signal hbm_01_arready : std_logic;
	signal hbm_01_rready : std_logic;
	signal hbm_01_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_01_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_01_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_01_rlast : std_logic;
	signal hbm_01_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_01_rvalid : std_logic;
	signal hbm_01_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_01_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_01_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_01_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_01_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_01_awvalid : std_logic;
	signal hbm_01_awready : std_logic;
	signal hbm_01_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_01_wlast : std_logic;
	signal hbm_01_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_01_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_01_wvalid : std_logic;
	signal hbm_01_wready : std_logic;
	signal hbm_01_bready : std_logic;
	signal hbm_01_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_01_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_01_bvalid : std_logic;

	signal hbm_02_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_02_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_02_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_02_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_02_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_02_arvalid : std_logic;
	signal hbm_02_arready : std_logic;
	signal hbm_02_rready : std_logic;
	signal hbm_02_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_02_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_02_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_02_rlast : std_logic;
	signal hbm_02_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_02_rvalid : std_logic;
	signal hbm_02_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_02_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_02_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_02_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_02_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_02_awvalid : std_logic;
	signal hbm_02_awready : std_logic;
	signal hbm_02_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_02_wlast : std_logic;
	signal hbm_02_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_02_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_02_wvalid : std_logic;
	signal hbm_02_wready : std_logic;
	signal hbm_02_bready : std_logic;
	signal hbm_02_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_02_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_02_bvalid : std_logic;

	signal hbm_03_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_03_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_03_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_03_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_03_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_03_arvalid : std_logic;
	signal hbm_03_arready : std_logic;
	signal hbm_03_rready : std_logic;
	signal hbm_03_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_03_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_03_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_03_rlast : std_logic;
	signal hbm_03_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_03_rvalid : std_logic;
	signal hbm_03_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_03_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_03_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_03_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_03_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_03_awvalid : std_logic;
	signal hbm_03_awready : std_logic;
	signal hbm_03_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_03_wlast : std_logic;
	signal hbm_03_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_03_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_03_wvalid : std_logic;
	signal hbm_03_wready : std_logic;
	signal hbm_03_bready : std_logic;
	signal hbm_03_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_03_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_03_bvalid : std_logic;

	signal hbm_04_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_04_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_04_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_04_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_04_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_04_arvalid : std_logic;
	signal hbm_04_arready : std_logic;
	signal hbm_04_rready : std_logic;
	signal hbm_04_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_04_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_04_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_04_rlast : std_logic;
	signal hbm_04_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_04_rvalid : std_logic;
	signal hbm_04_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_04_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_04_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_04_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_04_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_04_awvalid : std_logic;
	signal hbm_04_awready : std_logic;
	signal hbm_04_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_04_wlast : std_logic;
	signal hbm_04_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_04_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_04_wvalid : std_logic;
	signal hbm_04_wready : std_logic;
	signal hbm_04_bready : std_logic;
	signal hbm_04_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_04_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_04_bvalid : std_logic;

	signal hbm_05_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_05_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_05_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_05_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_05_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_05_arvalid : std_logic;
	signal hbm_05_arready : std_logic;
	signal hbm_05_rready : std_logic;
	signal hbm_05_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_05_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_05_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_05_rlast : std_logic;
	signal hbm_05_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_05_rvalid : std_logic;
	signal hbm_05_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_05_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_05_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_05_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_05_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_05_awvalid : std_logic;
	signal hbm_05_awready : std_logic;
	signal hbm_05_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_05_wlast : std_logic;
	signal hbm_05_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_05_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_05_wvalid : std_logic;
	signal hbm_05_wready : std_logic;
	signal hbm_05_bready : std_logic;
	signal hbm_05_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_05_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_05_bvalid : std_logic;

	signal hbm_06_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_06_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_06_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_06_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_06_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_06_arvalid : std_logic;
	signal hbm_06_arready : std_logic;
	signal hbm_06_rready : std_logic;
	signal hbm_06_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_06_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_06_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_06_rlast : std_logic;
	signal hbm_06_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_06_rvalid : std_logic;
	signal hbm_06_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_06_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_06_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_06_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_06_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_06_awvalid : std_logic;
	signal hbm_06_awready : std_logic;
	signal hbm_06_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_06_wlast : std_logic;
	signal hbm_06_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_06_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_06_wvalid : std_logic;
	signal hbm_06_wready : std_logic;
	signal hbm_06_bready : std_logic;
	signal hbm_06_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_06_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_06_bvalid : std_logic;

	signal hbm_07_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_07_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_07_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_07_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_07_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_07_arvalid : std_logic;
	signal hbm_07_arready : std_logic;
	signal hbm_07_rready : std_logic;
	signal hbm_07_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_07_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_07_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_07_rlast : std_logic;
	signal hbm_07_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_07_rvalid : std_logic;
	signal hbm_07_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_07_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_07_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_07_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_07_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_07_awvalid : std_logic;
	signal hbm_07_awready : std_logic;
	signal hbm_07_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_07_wlast : std_logic;
	signal hbm_07_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_07_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_07_wvalid : std_logic;
	signal hbm_07_wready : std_logic;
	signal hbm_07_bready : std_logic;
	signal hbm_07_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_07_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_07_bvalid : std_logic;

	signal hbm_08_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_08_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_08_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_08_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_08_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_08_arvalid : std_logic;
	signal hbm_08_arready : std_logic;
	signal hbm_08_rready : std_logic;
	signal hbm_08_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_08_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_08_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_08_rlast : std_logic;
	signal hbm_08_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_08_rvalid : std_logic;
	signal hbm_08_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_08_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_08_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_08_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_08_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_08_awvalid : std_logic;
	signal hbm_08_awready : std_logic;
	signal hbm_08_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_08_wlast : std_logic;
	signal hbm_08_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_08_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_08_wvalid : std_logic;
	signal hbm_08_wready : std_logic;
	signal hbm_08_bready : std_logic;
	signal hbm_08_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_08_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_08_bvalid : std_logic;

	signal hbm_09_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_09_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_09_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_09_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_09_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_09_arvalid : std_logic;
	signal hbm_09_arready : std_logic;
	signal hbm_09_rready : std_logic;
	signal hbm_09_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_09_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_09_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_09_rlast : std_logic;
	signal hbm_09_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_09_rvalid : std_logic;
	signal hbm_09_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_09_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_09_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_09_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_09_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_09_awvalid : std_logic;
	signal hbm_09_awready : std_logic;
	signal hbm_09_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_09_wlast : std_logic;
	signal hbm_09_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_09_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_09_wvalid : std_logic;
	signal hbm_09_wready : std_logic;
	signal hbm_09_bready : std_logic;
	signal hbm_09_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_09_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_09_bvalid : std_logic;

	signal hbm_10_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_10_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_10_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_10_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_10_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_10_arvalid : std_logic;
	signal hbm_10_arready : std_logic;
	signal hbm_10_rready : std_logic;
	signal hbm_10_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_10_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_10_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_10_rlast : std_logic;
	signal hbm_10_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_10_rvalid : std_logic;
	signal hbm_10_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_10_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_10_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_10_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_10_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_10_awvalid : std_logic;
	signal hbm_10_awready : std_logic;
	signal hbm_10_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_10_wlast : std_logic;
	signal hbm_10_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_10_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_10_wvalid : std_logic;
	signal hbm_10_wready : std_logic;
	signal hbm_10_bready : std_logic;
	signal hbm_10_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_10_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_10_bvalid : std_logic;

	signal hbm_11_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_11_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_11_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_11_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_11_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_11_arvalid : std_logic;
	signal hbm_11_arready : std_logic;
	signal hbm_11_rready : std_logic;
	signal hbm_11_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_11_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_11_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_11_rlast : std_logic;
	signal hbm_11_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_11_rvalid : std_logic;
	signal hbm_11_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_11_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_11_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_11_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_11_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_11_awvalid : std_logic;
	signal hbm_11_awready : std_logic;
	signal hbm_11_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_11_wlast : std_logic;
	signal hbm_11_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_11_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_11_wvalid : std_logic;
	signal hbm_11_wready : std_logic;
	signal hbm_11_bready : std_logic;
	signal hbm_11_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_11_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_11_bvalid : std_logic;

	signal hbm_12_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_12_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_12_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_12_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_12_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_12_arvalid : std_logic;
	signal hbm_12_arready : std_logic;
	signal hbm_12_rready : std_logic;
	signal hbm_12_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_12_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_12_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_12_rlast : std_logic;
	signal hbm_12_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_12_rvalid : std_logic;
	signal hbm_12_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_12_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_12_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_12_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_12_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_12_awvalid : std_logic;
	signal hbm_12_awready : std_logic;
	signal hbm_12_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_12_wlast : std_logic;
	signal hbm_12_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_12_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_12_wvalid : std_logic;
	signal hbm_12_wready : std_logic;
	signal hbm_12_bready : std_logic;
	signal hbm_12_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_12_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_12_bvalid : std_logic;

	signal hbm_13_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_13_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_13_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_13_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_13_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_13_arvalid : std_logic;
	signal hbm_13_arready : std_logic;
	signal hbm_13_rready : std_logic;
	signal hbm_13_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_13_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_13_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_13_rlast : std_logic;
	signal hbm_13_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_13_rvalid : std_logic;
	signal hbm_13_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_13_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_13_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_13_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_13_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_13_awvalid : std_logic;
	signal hbm_13_awready : std_logic;
	signal hbm_13_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_13_wlast : std_logic;
	signal hbm_13_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_13_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_13_wvalid : std_logic;
	signal hbm_13_wready : std_logic;
	signal hbm_13_bready : std_logic;
	signal hbm_13_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_13_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_13_bvalid : std_logic;

	signal hbm_14_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_14_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_14_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_14_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_14_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_14_arvalid : std_logic;
	signal hbm_14_arready : std_logic;
	signal hbm_14_rready : std_logic;
	signal hbm_14_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_14_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_14_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_14_rlast : std_logic;
	signal hbm_14_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_14_rvalid : std_logic;
	signal hbm_14_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_14_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_14_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_14_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_14_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_14_awvalid : std_logic;
	signal hbm_14_awready : std_logic;
	signal hbm_14_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_14_wlast : std_logic;
	signal hbm_14_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_14_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_14_wvalid : std_logic;
	signal hbm_14_wready : std_logic;
	signal hbm_14_bready : std_logic;
	signal hbm_14_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_14_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_14_bvalid : std_logic;

	signal hbm_15_araddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_15_arburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_15_arid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_15_arlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_15_arsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_15_arvalid : std_logic;
	signal hbm_15_arready : std_logic;
	signal hbm_15_rready : std_logic;
	signal hbm_15_rdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_15_rdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_15_rid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_15_rlast : std_logic;
	signal hbm_15_rresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_15_rvalid : std_logic;
	signal hbm_15_awaddr : std_logic_vector(hbm_addr_width-1 downto 0);
	signal hbm_15_awburst : std_logic_vector(hbm_burstmode_bit_width-1 downto 0);
	signal hbm_15_awid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_15_awlen : std_logic_vector(hbm_burstlen_bit_width-1 downto 0);
	signal hbm_15_awsize : std_logic_vector(hbm_burstsize_bit_width-1 downto 0);
	signal hbm_15_awvalid : std_logic;
	signal hbm_15_awready : std_logic;
	signal hbm_15_wdata : std_logic_vector(hbm_data_width-1 downto 0);
	signal hbm_15_wlast : std_logic;
	signal hbm_15_wstrb : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_15_wdata_parity : std_logic_vector(hbm_bytes_per_ps_port-1 downto 0);
	signal hbm_15_wvalid : std_logic;
	signal hbm_15_wready : std_logic;
	signal hbm_15_bready : std_logic;
	signal hbm_15_bid : std_logic_vector(hbm_id_bit_width-1 downto 0);
	signal hbm_15_bresp : std_logic_vector(hbm_resp_bit_width-1 downto 0);
	signal hbm_15_bvalid : std_logic;

begin


	HBM_R_SELECT <= HBM_RW_SELECT(1);
	HBM_W_SELECT <= HBM_RW_SELECT(0);

  ------------------------------------------------------------------
  -- HBM instance 
  ------------------------------------------------------------------
	hbm_1_inst: hbm_1
		port map (
			HBM_REF_CLK_0       => HBM_REF_CLK_0,
			-- AXI in short: the party that sends the data sets valid='1', the party that receives the data indicates that through ready='1'
			-- here we transmit read/write-address and the write-data and we receive the read-data
			
			-- ---- AXI_00 ----
			AXI_00_ACLK       => AXI_00_ACLK,
			AXI_00_ARESET_N    => AXI_00_ARESET_N,
			AXI_00_ARADDR      => hbm_00_araddr,
			AXI_00_ARBURST     => hbm_00_arburst,
			AXI_00_ARID        => hbm_00_arid,
			AXI_00_ARLEN       => hbm_00_arlen,
			AXI_00_ARSIZE      => hbm_00_arsize,
			AXI_00_ARVALID     => hbm_00_arvalid,
			AXI_00_ARREADY     => hbm_00_arready,
			AXI_00_RREADY      => hbm_00_rready,
			AXI_00_RDATA_PARITY => hbm_00_rdata_parity,
			AXI_00_RDATA       => hbm_00_rdata,
			AXI_00_RID         => hbm_00_rid,
			AXI_00_RLAST       => hbm_00_rlast,
			AXI_00_RRESP       => hbm_00_rresp,
			AXI_00_RVALID      => hbm_00_rvalid,
			AXI_00_AWADDR      => hbm_00_awaddr,
			AXI_00_AWBURST     => hbm_00_awburst,
			AXI_00_AWID        => hbm_00_awid,
			AXI_00_AWLEN       => hbm_00_awlen,
			AXI_00_AWSIZE      => hbm_00_awsize,
			AXI_00_AWVALID     => hbm_00_awvalid,
			AXI_00_AWREADY     => hbm_00_awready,
			AXI_00_WDATA       => hbm_00_wdata,
			AXI_00_WLAST       => hbm_00_wlast,
			AXI_00_WSTRB       => hbm_00_wstrb,
			AXI_00_WDATA_PARITY => hbm_00_wdata_parity,
			AXI_00_WVALID      => hbm_00_wvalid,
			AXI_00_WREADY      => hbm_00_wready,
			AXI_00_BREADY      => hbm_00_bready,
			AXI_00_BID         => hbm_00_bid,
			AXI_00_BRESP       => hbm_00_bresp,
			AXI_00_BVALID      => hbm_00_bvalid,

			-- ---- AXI_01 ----
			AXI_01_ACLK       => AXI_01_ACLK,
			AXI_01_ARESET_N    => AXI_01_ARESET_N,
			AXI_01_ARADDR      => hbm_01_araddr,
			AXI_01_ARBURST     => hbm_01_arburst,
			AXI_01_ARID        => hbm_01_arid,
			AXI_01_ARLEN       => hbm_01_arlen,
			AXI_01_ARSIZE      => hbm_01_arsize,
			AXI_01_ARVALID     => hbm_01_arvalid,
			AXI_01_ARREADY     => hbm_01_arready,
			AXI_01_RREADY      => hbm_01_rready,
			AXI_01_RDATA_PARITY => hbm_01_rdata_parity,
			AXI_01_RDATA       => hbm_01_rdata,
			AXI_01_RID         => hbm_01_rid,
			AXI_01_RLAST       => hbm_01_rlast,
			AXI_01_RRESP       => hbm_01_rresp,
			AXI_01_RVALID      => hbm_01_rvalid,
			AXI_01_AWADDR      => hbm_01_awaddr,
			AXI_01_AWBURST     => hbm_01_awburst,
			AXI_01_AWID        => hbm_01_awid,
			AXI_01_AWLEN       => hbm_01_awlen,
			AXI_01_AWSIZE      => hbm_01_awsize,
			AXI_01_AWVALID     => hbm_01_awvalid,
			AXI_01_AWREADY     => hbm_01_awready,
			AXI_01_WDATA       => hbm_01_wdata,
			AXI_01_WLAST       => hbm_01_wlast,
			AXI_01_WSTRB       => hbm_01_wstrb,
			AXI_01_WDATA_PARITY => hbm_01_wdata_parity,
			AXI_01_WVALID      => hbm_01_wvalid,
			AXI_01_WREADY      => hbm_01_wready,
			AXI_01_BREADY      => hbm_01_bready,
			AXI_01_BID         => hbm_01_bid,
			AXI_01_BRESP       => hbm_01_bresp,
			AXI_01_BVALID      => hbm_01_bvalid,

			-- ---- AXI_02 ----
			AXI_02_ACLK       => AXI_02_ACLK,
			AXI_02_ARESET_N    => AXI_02_ARESET_N,
			AXI_02_ARADDR      => hbm_02_araddr,
			AXI_02_ARBURST     => hbm_02_arburst,
			AXI_02_ARID        => hbm_02_arid,
			AXI_02_ARLEN       => hbm_02_arlen,
			AXI_02_ARSIZE      => hbm_02_arsize,
			AXI_02_ARVALID     => hbm_02_arvalid,
			AXI_02_ARREADY     => hbm_02_arready,
			AXI_02_RREADY      => hbm_02_rready,
			AXI_02_RDATA_PARITY => hbm_02_rdata_parity,
			AXI_02_RDATA       => hbm_02_rdata,
			AXI_02_RID         => hbm_02_rid,
			AXI_02_RLAST       => hbm_02_rlast,
			AXI_02_RRESP       => hbm_02_rresp,
			AXI_02_RVALID      => hbm_02_rvalid,
			AXI_02_AWADDR      => hbm_02_awaddr,
			AXI_02_AWBURST     => hbm_02_awburst,
			AXI_02_AWID        => hbm_02_awid,
			AXI_02_AWLEN       => hbm_02_awlen,
			AXI_02_AWSIZE      => hbm_02_awsize,
			AXI_02_AWVALID     => hbm_02_awvalid,
			AXI_02_AWREADY     => hbm_02_awready,
			AXI_02_WDATA       => hbm_02_wdata,
			AXI_02_WLAST       => hbm_02_wlast,
			AXI_02_WSTRB       => hbm_02_wstrb,
			AXI_02_WDATA_PARITY => hbm_02_wdata_parity,
			AXI_02_WVALID      => hbm_02_wvalid,
			AXI_02_WREADY      => hbm_02_wready,
			AXI_02_BREADY      => hbm_02_bready,
			AXI_02_BID         => hbm_02_bid,
			AXI_02_BRESP       => hbm_02_bresp,
			AXI_02_BVALID      => hbm_02_bvalid,

			-- ---- AXI_03 ----
			AXI_03_ACLK       => AXI_03_ACLK,
			AXI_03_ARESET_N    => AXI_03_ARESET_N,
			AXI_03_ARADDR      => hbm_03_araddr,
			AXI_03_ARBURST     => hbm_03_arburst,
			AXI_03_ARID        => hbm_03_arid,
			AXI_03_ARLEN       => hbm_03_arlen,
			AXI_03_ARSIZE      => hbm_03_arsize,
			AXI_03_ARVALID     => hbm_03_arvalid,
			AXI_03_ARREADY     => hbm_03_arready,
			AXI_03_RREADY      => hbm_03_rready,
			AXI_03_RDATA_PARITY => hbm_03_rdata_parity,
			AXI_03_RDATA       => hbm_03_rdata,
			AXI_03_RID         => hbm_03_rid,
			AXI_03_RLAST       => hbm_03_rlast,
			AXI_03_RRESP       => hbm_03_rresp,
			AXI_03_RVALID      => hbm_03_rvalid,
			AXI_03_AWADDR      => hbm_03_awaddr,
			AXI_03_AWBURST     => hbm_03_awburst,
			AXI_03_AWID        => hbm_03_awid,
			AXI_03_AWLEN       => hbm_03_awlen,
			AXI_03_AWSIZE      => hbm_03_awsize,
			AXI_03_AWVALID     => hbm_03_awvalid,
			AXI_03_AWREADY     => hbm_03_awready,
			AXI_03_WDATA       => hbm_03_wdata,
			AXI_03_WLAST       => hbm_03_wlast,
			AXI_03_WSTRB       => hbm_03_wstrb,
			AXI_03_WDATA_PARITY => hbm_03_wdata_parity,
			AXI_03_WVALID      => hbm_03_wvalid,
			AXI_03_WREADY      => hbm_03_wready,
			AXI_03_BREADY      => hbm_03_bready,
			AXI_03_BID         => hbm_03_bid,
			AXI_03_BRESP       => hbm_03_bresp,
			AXI_03_BVALID      => hbm_03_bvalid,

			-- ---- AXI_04 ----
			AXI_04_ACLK       => AXI_04_ACLK,
			AXI_04_ARESET_N    => AXI_04_ARESET_N,
			AXI_04_ARADDR      => hbm_04_araddr,
			AXI_04_ARBURST     => hbm_04_arburst,
			AXI_04_ARID        => hbm_04_arid,
			AXI_04_ARLEN       => hbm_04_arlen,
			AXI_04_ARSIZE      => hbm_04_arsize,
			AXI_04_ARVALID     => hbm_04_arvalid,
			AXI_04_ARREADY     => hbm_04_arready,
			AXI_04_RREADY      => hbm_04_rready,
			AXI_04_RDATA_PARITY => hbm_04_rdata_parity,
			AXI_04_RDATA       => hbm_04_rdata,
			AXI_04_RID         => hbm_04_rid,
			AXI_04_RLAST       => hbm_04_rlast,
			AXI_04_RRESP       => hbm_04_rresp,
			AXI_04_RVALID      => hbm_04_rvalid,
			AXI_04_AWADDR      => hbm_04_awaddr,
			AXI_04_AWBURST     => hbm_04_awburst,
			AXI_04_AWID        => hbm_04_awid,
			AXI_04_AWLEN       => hbm_04_awlen,
			AXI_04_AWSIZE      => hbm_04_awsize,
			AXI_04_AWVALID     => hbm_04_awvalid,
			AXI_04_AWREADY     => hbm_04_awready,
			AXI_04_WDATA       => hbm_04_wdata,
			AXI_04_WLAST       => hbm_04_wlast,
			AXI_04_WSTRB       => hbm_04_wstrb,
			AXI_04_WDATA_PARITY => hbm_04_wdata_parity,
			AXI_04_WVALID      => hbm_04_wvalid,
			AXI_04_WREADY      => hbm_04_wready,
			AXI_04_BREADY      => hbm_04_bready,
			AXI_04_BID         => hbm_04_bid,
			AXI_04_BRESP       => hbm_04_bresp,
			AXI_04_BVALID      => hbm_04_bvalid,

			-- ---- AXI_05 ----
			AXI_05_ACLK       => AXI_05_ACLK,
			AXI_05_ARESET_N    => AXI_05_ARESET_N,
			AXI_05_ARADDR      => hbm_05_araddr,
			AXI_05_ARBURST     => hbm_05_arburst,
			AXI_05_ARID        => hbm_05_arid,
			AXI_05_ARLEN       => hbm_05_arlen,
			AXI_05_ARSIZE      => hbm_05_arsize,
			AXI_05_ARVALID     => hbm_05_arvalid,
			AXI_05_ARREADY     => hbm_05_arready,
			AXI_05_RREADY      => hbm_05_rready,
			AXI_05_RDATA_PARITY => hbm_05_rdata_parity,
			AXI_05_RDATA       => hbm_05_rdata,
			AXI_05_RID         => hbm_05_rid,
			AXI_05_RLAST       => hbm_05_rlast,
			AXI_05_RRESP       => hbm_05_rresp,
			AXI_05_RVALID      => hbm_05_rvalid,
			AXI_05_AWADDR      => hbm_05_awaddr,
			AXI_05_AWBURST     => hbm_05_awburst,
			AXI_05_AWID        => hbm_05_awid,
			AXI_05_AWLEN       => hbm_05_awlen,
			AXI_05_AWSIZE      => hbm_05_awsize,
			AXI_05_AWVALID     => hbm_05_awvalid,
			AXI_05_AWREADY     => hbm_05_awready,
			AXI_05_WDATA       => hbm_05_wdata,
			AXI_05_WLAST       => hbm_05_wlast,
			AXI_05_WSTRB       => hbm_05_wstrb,
			AXI_05_WDATA_PARITY => hbm_05_wdata_parity,
			AXI_05_WVALID      => hbm_05_wvalid,
			AXI_05_WREADY      => hbm_05_wready,
			AXI_05_BREADY      => hbm_05_bready,
			AXI_05_BID         => hbm_05_bid,
			AXI_05_BRESP       => hbm_05_bresp,
			AXI_05_BVALID      => hbm_05_bvalid,

			-- ---- AXI_06 ----
			AXI_06_ACLK       => AXI_06_ACLK,
			AXI_06_ARESET_N    => AXI_06_ARESET_N,
			AXI_06_ARADDR      => hbm_06_araddr,
			AXI_06_ARBURST     => hbm_06_arburst,
			AXI_06_ARID        => hbm_06_arid,
			AXI_06_ARLEN       => hbm_06_arlen,
			AXI_06_ARSIZE      => hbm_06_arsize,
			AXI_06_ARVALID     => hbm_06_arvalid,
			AXI_06_ARREADY     => hbm_06_arready,
			AXI_06_RREADY      => hbm_06_rready,
			AXI_06_RDATA_PARITY => hbm_06_rdata_parity,
			AXI_06_RDATA       => hbm_06_rdata,
			AXI_06_RID         => hbm_06_rid,
			AXI_06_RLAST       => hbm_06_rlast,
			AXI_06_RRESP       => hbm_06_rresp,
			AXI_06_RVALID      => hbm_06_rvalid,
			AXI_06_AWADDR      => hbm_06_awaddr,
			AXI_06_AWBURST     => hbm_06_awburst,
			AXI_06_AWID        => hbm_06_awid,
			AXI_06_AWLEN       => hbm_06_awlen,
			AXI_06_AWSIZE      => hbm_06_awsize,
			AXI_06_AWVALID     => hbm_06_awvalid,
			AXI_06_AWREADY     => hbm_06_awready,
			AXI_06_WDATA       => hbm_06_wdata,
			AXI_06_WLAST       => hbm_06_wlast,
			AXI_06_WSTRB       => hbm_06_wstrb,
			AXI_06_WDATA_PARITY => hbm_06_wdata_parity,
			AXI_06_WVALID      => hbm_06_wvalid,
			AXI_06_WREADY      => hbm_06_wready,
			AXI_06_BREADY      => hbm_06_bready,
			AXI_06_BID         => hbm_06_bid,
			AXI_06_BRESP       => hbm_06_bresp,
			AXI_06_BVALID      => hbm_06_bvalid,

			-- ---- AXI_07 ----
			AXI_07_ACLK       => AXI_07_ACLK,
			AXI_07_ARESET_N    => AXI_07_ARESET_N,
			AXI_07_ARADDR      => hbm_07_araddr,
			AXI_07_ARBURST     => hbm_07_arburst,
			AXI_07_ARID        => hbm_07_arid,
			AXI_07_ARLEN       => hbm_07_arlen,
			AXI_07_ARSIZE      => hbm_07_arsize,
			AXI_07_ARVALID     => hbm_07_arvalid,
			AXI_07_ARREADY     => hbm_07_arready,
			AXI_07_RREADY      => hbm_07_rready,
			AXI_07_RDATA_PARITY => hbm_07_rdata_parity,
			AXI_07_RDATA       => hbm_07_rdata,
			AXI_07_RID         => hbm_07_rid,
			AXI_07_RLAST       => hbm_07_rlast,
			AXI_07_RRESP       => hbm_07_rresp,
			AXI_07_RVALID      => hbm_07_rvalid,
			AXI_07_AWADDR      => hbm_07_awaddr,
			AXI_07_AWBURST     => hbm_07_awburst,
			AXI_07_AWID        => hbm_07_awid,
			AXI_07_AWLEN       => hbm_07_awlen,
			AXI_07_AWSIZE      => hbm_07_awsize,
			AXI_07_AWVALID     => hbm_07_awvalid,
			AXI_07_AWREADY     => hbm_07_awready,
			AXI_07_WDATA       => hbm_07_wdata,
			AXI_07_WLAST       => hbm_07_wlast,
			AXI_07_WSTRB       => hbm_07_wstrb,
			AXI_07_WDATA_PARITY => hbm_07_wdata_parity,
			AXI_07_WVALID      => hbm_07_wvalid,
			AXI_07_WREADY      => hbm_07_wready,
			AXI_07_BREADY      => hbm_07_bready,
			AXI_07_BID         => hbm_07_bid,
			AXI_07_BRESP       => hbm_07_bresp,
			AXI_07_BVALID      => hbm_07_bvalid,

			-- ---- AXI_08 ----
			AXI_08_ACLK       => AXI_08_ACLK,
			AXI_08_ARESET_N    => AXI_08_ARESET_N,
			AXI_08_ARADDR      => hbm_08_araddr,
			AXI_08_ARBURST     => hbm_08_arburst,
			AXI_08_ARID        => hbm_08_arid,
			AXI_08_ARLEN       => hbm_08_arlen,
			AXI_08_ARSIZE      => hbm_08_arsize,
			AXI_08_ARVALID     => hbm_08_arvalid,
			AXI_08_ARREADY     => hbm_08_arready,
			AXI_08_RREADY      => hbm_08_rready,
			AXI_08_RDATA_PARITY => hbm_08_rdata_parity,
			AXI_08_RDATA       => hbm_08_rdata,
			AXI_08_RID         => hbm_08_rid,
			AXI_08_RLAST       => hbm_08_rlast,
			AXI_08_RRESP       => hbm_08_rresp,
			AXI_08_RVALID      => hbm_08_rvalid,
			AXI_08_AWADDR      => hbm_08_awaddr,
			AXI_08_AWBURST     => hbm_08_awburst,
			AXI_08_AWID        => hbm_08_awid,
			AXI_08_AWLEN       => hbm_08_awlen,
			AXI_08_AWSIZE      => hbm_08_awsize,
			AXI_08_AWVALID     => hbm_08_awvalid,
			AXI_08_AWREADY     => hbm_08_awready,
			AXI_08_WDATA       => hbm_08_wdata,
			AXI_08_WLAST       => hbm_08_wlast,
			AXI_08_WSTRB       => hbm_08_wstrb,
			AXI_08_WDATA_PARITY => hbm_08_wdata_parity,
			AXI_08_WVALID      => hbm_08_wvalid,
			AXI_08_WREADY      => hbm_08_wready,
			AXI_08_BREADY      => hbm_08_bready,
			AXI_08_BID         => hbm_08_bid,
			AXI_08_BRESP       => hbm_08_bresp,
			AXI_08_BVALID      => hbm_08_bvalid,

			-- ---- AXI_09 ----
			AXI_09_ACLK       => AXI_09_ACLK,
			AXI_09_ARESET_N    => AXI_09_ARESET_N,
			AXI_09_ARADDR      => hbm_09_araddr,
			AXI_09_ARBURST     => hbm_09_arburst,
			AXI_09_ARID        => hbm_09_arid,
			AXI_09_ARLEN       => hbm_09_arlen,
			AXI_09_ARSIZE      => hbm_09_arsize,
			AXI_09_ARVALID     => hbm_09_arvalid,
			AXI_09_ARREADY     => hbm_09_arready,
			AXI_09_RREADY      => hbm_09_rready,
			AXI_09_RDATA_PARITY => hbm_09_rdata_parity,
			AXI_09_RDATA       => hbm_09_rdata,
			AXI_09_RID         => hbm_09_rid,
			AXI_09_RLAST       => hbm_09_rlast,
			AXI_09_RRESP       => hbm_09_rresp,
			AXI_09_RVALID      => hbm_09_rvalid,
			AXI_09_AWADDR      => hbm_09_awaddr,
			AXI_09_AWBURST     => hbm_09_awburst,
			AXI_09_AWID        => hbm_09_awid,
			AXI_09_AWLEN       => hbm_09_awlen,
			AXI_09_AWSIZE      => hbm_09_awsize,
			AXI_09_AWVALID     => hbm_09_awvalid,
			AXI_09_AWREADY     => hbm_09_awready,
			AXI_09_WDATA       => hbm_09_wdata,
			AXI_09_WLAST       => hbm_09_wlast,
			AXI_09_WSTRB       => hbm_09_wstrb,
			AXI_09_WDATA_PARITY => hbm_09_wdata_parity,
			AXI_09_WVALID      => hbm_09_wvalid,
			AXI_09_WREADY      => hbm_09_wready,
			AXI_09_BREADY      => hbm_09_bready,
			AXI_09_BID         => hbm_09_bid,
			AXI_09_BRESP       => hbm_09_bresp,
			AXI_09_BVALID      => hbm_09_bvalid,

			-- ---- AXI_10 ----
			AXI_10_ACLK       => AXI_10_ACLK,
			AXI_10_ARESET_N    => AXI_10_ARESET_N,
			AXI_10_ARADDR      => hbm_10_araddr,
			AXI_10_ARBURST     => hbm_10_arburst,
			AXI_10_ARID        => hbm_10_arid,
			AXI_10_ARLEN       => hbm_10_arlen,
			AXI_10_ARSIZE      => hbm_10_arsize,
			AXI_10_ARVALID     => hbm_10_arvalid,
			AXI_10_ARREADY     => hbm_10_arready,
			AXI_10_RREADY      => hbm_10_rready,
			AXI_10_RDATA_PARITY => hbm_10_rdata_parity,
			AXI_10_RDATA       => hbm_10_rdata,
			AXI_10_RID         => hbm_10_rid,
			AXI_10_RLAST       => hbm_10_rlast,
			AXI_10_RRESP       => hbm_10_rresp,
			AXI_10_RVALID      => hbm_10_rvalid,
			AXI_10_AWADDR      => hbm_10_awaddr,
			AXI_10_AWBURST     => hbm_10_awburst,
			AXI_10_AWID        => hbm_10_awid,
			AXI_10_AWLEN       => hbm_10_awlen,
			AXI_10_AWSIZE      => hbm_10_awsize,
			AXI_10_AWVALID     => hbm_10_awvalid,
			AXI_10_AWREADY     => hbm_10_awready,
			AXI_10_WDATA       => hbm_10_wdata,
			AXI_10_WLAST       => hbm_10_wlast,
			AXI_10_WSTRB       => hbm_10_wstrb,
			AXI_10_WDATA_PARITY => hbm_10_wdata_parity,
			AXI_10_WVALID      => hbm_10_wvalid,
			AXI_10_WREADY      => hbm_10_wready,
			AXI_10_BREADY      => hbm_10_bready,
			AXI_10_BID         => hbm_10_bid,
			AXI_10_BRESP       => hbm_10_bresp,
			AXI_10_BVALID      => hbm_10_bvalid,

			-- ---- AXI_11 ----
			AXI_11_ACLK       => AXI_11_ACLK,
			AXI_11_ARESET_N    => AXI_11_ARESET_N,
			AXI_11_ARADDR      => hbm_11_araddr,
			AXI_11_ARBURST     => hbm_11_arburst,
			AXI_11_ARID        => hbm_11_arid,
			AXI_11_ARLEN       => hbm_11_arlen,
			AXI_11_ARSIZE      => hbm_11_arsize,
			AXI_11_ARVALID     => hbm_11_arvalid,
			AXI_11_ARREADY     => hbm_11_arready,
			AXI_11_RREADY      => hbm_11_rready,
			AXI_11_RDATA_PARITY => hbm_11_rdata_parity,
			AXI_11_RDATA       => hbm_11_rdata,
			AXI_11_RID         => hbm_11_rid,
			AXI_11_RLAST       => hbm_11_rlast,
			AXI_11_RRESP       => hbm_11_rresp,
			AXI_11_RVALID      => hbm_11_rvalid,
			AXI_11_AWADDR      => hbm_11_awaddr,
			AXI_11_AWBURST     => hbm_11_awburst,
			AXI_11_AWID        => hbm_11_awid,
			AXI_11_AWLEN       => hbm_11_awlen,
			AXI_11_AWSIZE      => hbm_11_awsize,
			AXI_11_AWVALID     => hbm_11_awvalid,
			AXI_11_AWREADY     => hbm_11_awready,
			AXI_11_WDATA       => hbm_11_wdata,
			AXI_11_WLAST       => hbm_11_wlast,
			AXI_11_WSTRB       => hbm_11_wstrb,
			AXI_11_WDATA_PARITY => hbm_11_wdata_parity,
			AXI_11_WVALID      => hbm_11_wvalid,
			AXI_11_WREADY      => hbm_11_wready,
			AXI_11_BREADY      => hbm_11_bready,
			AXI_11_BID         => hbm_11_bid,
			AXI_11_BRESP       => hbm_11_bresp,
			AXI_11_BVALID      => hbm_11_bvalid,

			-- ---- AXI_12 ----
			AXI_12_ACLK       => AXI_12_ACLK,
			AXI_12_ARESET_N    => AXI_12_ARESET_N,
			AXI_12_ARADDR      => hbm_12_araddr,
			AXI_12_ARBURST     => hbm_12_arburst,
			AXI_12_ARID        => hbm_12_arid,
			AXI_12_ARLEN       => hbm_12_arlen,
			AXI_12_ARSIZE      => hbm_12_arsize,
			AXI_12_ARVALID     => hbm_12_arvalid,
			AXI_12_ARREADY     => hbm_12_arready,
			AXI_12_RREADY      => hbm_12_rready,
			AXI_12_RDATA_PARITY => hbm_12_rdata_parity,
			AXI_12_RDATA       => hbm_12_rdata,
			AXI_12_RID         => hbm_12_rid,
			AXI_12_RLAST       => hbm_12_rlast,
			AXI_12_RRESP       => hbm_12_rresp,
			AXI_12_RVALID      => hbm_12_rvalid,
			AXI_12_AWADDR      => hbm_12_awaddr,
			AXI_12_AWBURST     => hbm_12_awburst,
			AXI_12_AWID        => hbm_12_awid,
			AXI_12_AWLEN       => hbm_12_awlen,
			AXI_12_AWSIZE      => hbm_12_awsize,
			AXI_12_AWVALID     => hbm_12_awvalid,
			AXI_12_AWREADY     => hbm_12_awready,
			AXI_12_WDATA       => hbm_12_wdata,
			AXI_12_WLAST       => hbm_12_wlast,
			AXI_12_WSTRB       => hbm_12_wstrb,
			AXI_12_WDATA_PARITY => hbm_12_wdata_parity,
			AXI_12_WVALID      => hbm_12_wvalid,
			AXI_12_WREADY      => hbm_12_wready,
			AXI_12_BREADY      => hbm_12_bready,
			AXI_12_BID         => hbm_12_bid,
			AXI_12_BRESP       => hbm_12_bresp,
			AXI_12_BVALID      => hbm_12_bvalid,

			-- ---- AXI_13 ----
			AXI_13_ACLK       => AXI_13_ACLK,
			AXI_13_ARESET_N    => AXI_13_ARESET_N,
			AXI_13_ARADDR      => hbm_13_araddr,
			AXI_13_ARBURST     => hbm_13_arburst,
			AXI_13_ARID        => hbm_13_arid,
			AXI_13_ARLEN       => hbm_13_arlen,
			AXI_13_ARSIZE      => hbm_13_arsize,
			AXI_13_ARVALID     => hbm_13_arvalid,
			AXI_13_ARREADY     => hbm_13_arready,
			AXI_13_RREADY      => hbm_13_rready,
			AXI_13_RDATA_PARITY => hbm_13_rdata_parity,
			AXI_13_RDATA       => hbm_13_rdata,
			AXI_13_RID         => hbm_13_rid,
			AXI_13_RLAST       => hbm_13_rlast,
			AXI_13_RRESP       => hbm_13_rresp,
			AXI_13_RVALID      => hbm_13_rvalid,
			AXI_13_AWADDR      => hbm_13_awaddr,
			AXI_13_AWBURST     => hbm_13_awburst,
			AXI_13_AWID        => hbm_13_awid,
			AXI_13_AWLEN       => hbm_13_awlen,
			AXI_13_AWSIZE      => hbm_13_awsize,
			AXI_13_AWVALID     => hbm_13_awvalid,
			AXI_13_AWREADY     => hbm_13_awready,
			AXI_13_WDATA       => hbm_13_wdata,
			AXI_13_WLAST       => hbm_13_wlast,
			AXI_13_WSTRB       => hbm_13_wstrb,
			AXI_13_WDATA_PARITY => hbm_13_wdata_parity,
			AXI_13_WVALID      => hbm_13_wvalid,
			AXI_13_WREADY      => hbm_13_wready,
			AXI_13_BREADY      => hbm_13_bready,
			AXI_13_BID         => hbm_13_bid,
			AXI_13_BRESP       => hbm_13_bresp,
			AXI_13_BVALID      => hbm_13_bvalid,

			-- ---- AXI_14 ----
			AXI_14_ACLK       => AXI_14_ACLK,
			AXI_14_ARESET_N    => AXI_14_ARESET_N,
			AXI_14_ARADDR      => hbm_14_araddr,
			AXI_14_ARBURST     => hbm_14_arburst,
			AXI_14_ARID        => hbm_14_arid,
			AXI_14_ARLEN       => hbm_14_arlen,
			AXI_14_ARSIZE      => hbm_14_arsize,
			AXI_14_ARVALID     => hbm_14_arvalid,
			AXI_14_ARREADY     => hbm_14_arready,
			AXI_14_RREADY      => hbm_14_rready,
			AXI_14_RDATA_PARITY => hbm_14_rdata_parity,
			AXI_14_RDATA       => hbm_14_rdata,
			AXI_14_RID         => hbm_14_rid,
			AXI_14_RLAST       => hbm_14_rlast,
			AXI_14_RRESP       => hbm_14_rresp,
			AXI_14_RVALID      => hbm_14_rvalid,
			AXI_14_AWADDR      => hbm_14_awaddr,
			AXI_14_AWBURST     => hbm_14_awburst,
			AXI_14_AWID        => hbm_14_awid,
			AXI_14_AWLEN       => hbm_14_awlen,
			AXI_14_AWSIZE      => hbm_14_awsize,
			AXI_14_AWVALID     => hbm_14_awvalid,
			AXI_14_AWREADY     => hbm_14_awready,
			AXI_14_WDATA       => hbm_14_wdata,
			AXI_14_WLAST       => hbm_14_wlast,
			AXI_14_WSTRB       => hbm_14_wstrb,
			AXI_14_WDATA_PARITY => hbm_14_wdata_parity,
			AXI_14_WVALID      => hbm_14_wvalid,
			AXI_14_WREADY      => hbm_14_wready,
			AXI_14_BREADY      => hbm_14_bready,
			AXI_14_BID         => hbm_14_bid,
			AXI_14_BRESP       => hbm_14_bresp,
			AXI_14_BVALID      => hbm_14_bvalid,

			-- ---- AXI_15 ----
			AXI_15_ACLK       => AXI_15_ACLK,
			AXI_15_ARESET_N    => AXI_15_ARESET_N,
			AXI_15_ARADDR      => hbm_15_araddr,
			AXI_15_ARBURST     => hbm_15_arburst,
			AXI_15_ARID        => hbm_15_arid,
			AXI_15_ARLEN       => hbm_15_arlen,
			AXI_15_ARSIZE      => hbm_15_arsize,
			AXI_15_ARVALID     => hbm_15_arvalid,
			AXI_15_ARREADY     => hbm_15_arready,
			AXI_15_RREADY      => hbm_15_rready,
			AXI_15_RDATA_PARITY => hbm_15_rdata_parity,
			AXI_15_RDATA       => hbm_15_rdata,
			AXI_15_RID         => hbm_15_rid,
			AXI_15_RLAST       => hbm_15_rlast,
			AXI_15_RRESP       => hbm_15_rresp,
			AXI_15_RVALID      => hbm_15_rvalid,
			AXI_15_AWADDR      => hbm_15_awaddr,
			AXI_15_AWBURST     => hbm_15_awburst,
			AXI_15_AWID        => hbm_15_awid,
			AXI_15_AWLEN       => hbm_15_awlen,
			AXI_15_AWSIZE      => hbm_15_awsize,
			AXI_15_AWVALID     => hbm_15_awvalid,
			AXI_15_AWREADY     => hbm_15_awready,
			AXI_15_WDATA       => hbm_15_wdata,
			AXI_15_WLAST       => hbm_15_wlast,
			AXI_15_WSTRB       => hbm_15_wstrb,
			AXI_15_WDATA_PARITY => hbm_15_wdata_parity,
			AXI_15_WVALID      => hbm_15_wvalid,
			AXI_15_WREADY      => hbm_15_wready,
			AXI_15_BREADY      => hbm_15_bready,
			AXI_15_BID         => hbm_15_bid,
			AXI_15_BRESP       => hbm_15_bresp,
			AXI_15_BVALID      => hbm_15_bvalid,


			APB_0_PCLK          => APB_0_PCLK,
			APB_0_PRESET_N      => APB_0_PRESET_N,

			-- -- hbm read does not work if we don't drive these ports with zeros?
			-- APB_0_PWDATA        => (others => '0'),
			-- APB_0_PADDR         => (others => '0'),
			-- APB_0_PENABLE       => '0',
			-- APB_0_PSEL          => '0',
			-- APB_0_PWRITE        => '0',
			-- APB_0_PRDATA        => open,
			-- APB_0_PREADY        => open,
			-- APB_0_PSLVERR       => open,
			apb_complete_0      => o_initial_init_ready,
			DRAM_0_STAT_CATTRIP => open,
			DRAM_0_STAT_TEMP    => open
		);

	-- ==================================================
	-- MUX INPUTS INTO HBM + DEMUX OUTPUTS OUT OF HBM
	-- ==================================================

	-- Convention: select='0' => HOST owns that channel, select='1' => TFHE owns that channel
	-------------------- AXI_00 --------------------
	hbm_00_araddr <= AXI_00_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(0).araddr);
	hbm_00_arburst <= AXI_00_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_00_arid <= AXI_00_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(0).arid;
	hbm_00_arlen <= AXI_00_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(0).arlen;
	hbm_00_arsize <= AXI_00_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_00_arvalid <= AXI_00_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(0).arvalid;
	hbm_00_rready <= AXI_00_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(0).rready;

	AXI_00_ARREADY <= hbm_00_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(0).arready <= hbm_00_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_00_RDATA_PARITY <= hbm_00_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(0).rdata_parity <= hbm_00_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_00_RDATA <= hbm_00_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(0).rdata <= hbm_00_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_00_RID <= hbm_00_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(0).rid <= hbm_00_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_00_RLAST <= hbm_00_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(0).rlast <= hbm_00_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_00_RRESP <= hbm_00_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(0).rresp <= hbm_00_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_00_RVALID <= hbm_00_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(0).rvalid <= hbm_00_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_00_awaddr <= AXI_00_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(0).awaddr);
	hbm_00_awburst <= AXI_00_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_00_awid <= AXI_00_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(0).awid;
	hbm_00_awlen <= AXI_00_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(0).awlen;
	hbm_00_awsize <= AXI_00_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_00_awvalid <= AXI_00_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(0).awvalid;
	hbm_00_wdata <= AXI_00_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(0).wdata;
	hbm_00_wlast <= AXI_00_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(0).wlast;
	hbm_00_wstrb <= AXI_00_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_00_wdata_parity <= AXI_00_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(0).wdata_parity;
	hbm_00_wvalid <= AXI_00_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(0).wvalid;
	hbm_00_bready <= AXI_00_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(0).bready;

	AXI_00_AWREADY <= hbm_00_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(0).awready <= hbm_00_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_00_WREADY <= hbm_00_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(0).wready <= hbm_00_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_00_BID <= hbm_00_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(0).bid <= hbm_00_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_00_BRESP <= hbm_00_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(0).bresp <= hbm_00_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_00_BVALID <= hbm_00_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(0).bvalid <= hbm_00_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_01 --------------------
	hbm_01_araddr <= AXI_01_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(1).araddr);
	hbm_01_arburst <= AXI_01_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_01_arid <= AXI_01_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(1).arid;
	hbm_01_arlen <= AXI_01_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(1).arlen;
	hbm_01_arsize <= AXI_01_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_01_arvalid <= AXI_01_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(1).arvalid;
	hbm_01_rready <= AXI_01_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(1).rready;

	AXI_01_ARREADY <= hbm_01_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(1).arready <= hbm_01_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_01_RDATA_PARITY <= hbm_01_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(1).rdata_parity <= hbm_01_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_01_RDATA <= hbm_01_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(1).rdata <= hbm_01_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_01_RID <= hbm_01_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(1).rid <= hbm_01_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_01_RLAST <= hbm_01_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(1).rlast <= hbm_01_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_01_RRESP <= hbm_01_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(1).rresp <= hbm_01_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_01_RVALID <= hbm_01_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(1).rvalid <= hbm_01_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_01_awaddr <= AXI_01_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(1).awaddr);
	hbm_01_awburst <= AXI_01_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_01_awid <= AXI_01_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(1).awid;
	hbm_01_awlen <= AXI_01_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(1).awlen;
	hbm_01_awsize <= AXI_01_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_01_awvalid <= AXI_01_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(1).awvalid;
	hbm_01_wdata <= AXI_01_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(1).wdata;
	hbm_01_wlast <= AXI_01_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(1).wlast;
	hbm_01_wstrb <= AXI_01_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_01_wdata_parity <= AXI_01_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(1).wdata_parity;
	hbm_01_wvalid <= AXI_01_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(1).wvalid;
	hbm_01_bready <= AXI_01_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(1).bready;

	AXI_01_AWREADY <= hbm_01_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(1).awready <= hbm_01_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_01_WREADY <= hbm_01_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(1).wready <= hbm_01_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_01_BID <= hbm_01_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(1).bid <= hbm_01_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_01_BRESP <= hbm_01_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(1).bresp <= hbm_01_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_01_BVALID <= hbm_01_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(1).bvalid <= hbm_01_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_02 --------------------
	hbm_02_araddr <= AXI_02_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(2).araddr);
	hbm_02_arburst <= AXI_02_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_02_arid <= AXI_02_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(2).arid;
	hbm_02_arlen <= AXI_02_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(2).arlen;
	hbm_02_arsize <= AXI_02_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_02_arvalid <= AXI_02_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(2).arvalid;
	hbm_02_rready <= AXI_02_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(2).rready;

	AXI_02_ARREADY <= hbm_02_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(2).arready <= hbm_02_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_02_RDATA_PARITY <= hbm_02_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(2).rdata_parity <= hbm_02_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_02_RDATA <= hbm_02_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(2).rdata <= hbm_02_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_02_RID <= hbm_02_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(2).rid <= hbm_02_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_02_RLAST <= hbm_02_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(2).rlast <= hbm_02_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_02_RRESP <= hbm_02_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(2).rresp <= hbm_02_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_02_RVALID <= hbm_02_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(2).rvalid <= hbm_02_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_02_awaddr <= AXI_02_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(2).awaddr);
	hbm_02_awburst <= AXI_02_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_02_awid <= AXI_02_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(2).awid;
	hbm_02_awlen <= AXI_02_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(2).awlen;
	hbm_02_awsize <= AXI_02_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_02_awvalid <= AXI_02_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(2).awvalid;
	hbm_02_wdata <= AXI_02_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(2).wdata;
	hbm_02_wlast <= AXI_02_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(2).wlast;
	hbm_02_wstrb <= AXI_02_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_02_wdata_parity <= AXI_02_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(2).wdata_parity;
	hbm_02_wvalid <= AXI_02_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(2).wvalid;
	hbm_02_bready <= AXI_02_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(2).bready;

	AXI_02_AWREADY <= hbm_02_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(2).awready <= hbm_02_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_02_WREADY <= hbm_02_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(2).wready <= hbm_02_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_02_BID <= hbm_02_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(2).bid <= hbm_02_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_02_BRESP <= hbm_02_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(2).bresp <= hbm_02_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_02_BVALID <= hbm_02_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(2).bvalid <= hbm_02_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_03 --------------------
	hbm_03_araddr <= AXI_03_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(3).araddr);
	hbm_03_arburst <= AXI_03_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_03_arid <= AXI_03_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(3).arid;
	hbm_03_arlen <= AXI_03_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(3).arlen;
	hbm_03_arsize <= AXI_03_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_03_arvalid <= AXI_03_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(3).arvalid;
	hbm_03_rready <= AXI_03_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(3).rready;

	AXI_03_ARREADY <= hbm_03_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(3).arready <= hbm_03_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_03_RDATA_PARITY <= hbm_03_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(3).rdata_parity <= hbm_03_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_03_RDATA <= hbm_03_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(3).rdata <= hbm_03_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_03_RID <= hbm_03_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(3).rid <= hbm_03_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_03_RLAST <= hbm_03_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(3).rlast <= hbm_03_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_03_RRESP <= hbm_03_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(3).rresp <= hbm_03_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_03_RVALID <= hbm_03_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(3).rvalid <= hbm_03_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_03_awaddr <= AXI_03_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(3).awaddr);
	hbm_03_awburst <= AXI_03_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_03_awid <= AXI_03_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(3).awid;
	hbm_03_awlen <= AXI_03_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(3).awlen;
	hbm_03_awsize <= AXI_03_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_03_awvalid <= AXI_03_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(3).awvalid;
	hbm_03_wdata <= AXI_03_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(3).wdata;
	hbm_03_wlast <= AXI_03_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(3).wlast;
	hbm_03_wstrb <= AXI_03_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_03_wdata_parity <= AXI_03_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(3).wdata_parity;
	hbm_03_wvalid <= AXI_03_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(3).wvalid;
	hbm_03_bready <= AXI_03_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(3).bready;

	AXI_03_AWREADY <= hbm_03_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(3).awready <= hbm_03_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_03_WREADY <= hbm_03_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(3).wready <= hbm_03_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_03_BID <= hbm_03_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(3).bid <= hbm_03_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_03_BRESP <= hbm_03_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(3).bresp <= hbm_03_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_03_BVALID <= hbm_03_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(3).bvalid <= hbm_03_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_04 --------------------
	hbm_04_araddr <= AXI_04_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(4).araddr);
	hbm_04_arburst <= AXI_04_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_04_arid <= AXI_04_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(4).arid;
	hbm_04_arlen <= AXI_04_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(4).arlen;
	hbm_04_arsize <= AXI_04_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_04_arvalid <= AXI_04_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(4).arvalid;
	hbm_04_rready <= AXI_04_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(4).rready;

	AXI_04_ARREADY <= hbm_04_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(4).arready <= hbm_04_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_04_RDATA_PARITY <= hbm_04_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(4).rdata_parity <= hbm_04_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_04_RDATA <= hbm_04_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(4).rdata <= hbm_04_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_04_RID <= hbm_04_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(4).rid <= hbm_04_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_04_RLAST <= hbm_04_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(4).rlast <= hbm_04_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_04_RRESP <= hbm_04_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(4).rresp <= hbm_04_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_04_RVALID <= hbm_04_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(4).rvalid <= hbm_04_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_04_awaddr <= AXI_04_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(4).awaddr);
	hbm_04_awburst <= AXI_04_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_04_awid <= AXI_04_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(4).awid;
	hbm_04_awlen <= AXI_04_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(4).awlen;
	hbm_04_awsize <= AXI_04_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_04_awvalid <= AXI_04_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(4).awvalid;
	hbm_04_wdata <= AXI_04_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(4).wdata;
	hbm_04_wlast <= AXI_04_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(4).wlast;
	hbm_04_wstrb <= AXI_04_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_04_wdata_parity <= AXI_04_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(4).wdata_parity;
	hbm_04_wvalid <= AXI_04_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(4).wvalid;
	hbm_04_bready <= AXI_04_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(4).bready;

	AXI_04_AWREADY <= hbm_04_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(4).awready <= hbm_04_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_04_WREADY <= hbm_04_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(4).wready <= hbm_04_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_04_BID <= hbm_04_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(4).bid <= hbm_04_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_04_BRESP <= hbm_04_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(4).bresp <= hbm_04_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_04_BVALID <= hbm_04_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(4).bvalid <= hbm_04_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_05 --------------------
	hbm_05_araddr <= AXI_05_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(5).araddr);
	hbm_05_arburst <= AXI_05_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_05_arid <= AXI_05_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(5).arid;
	hbm_05_arlen <= AXI_05_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(5).arlen;
	hbm_05_arsize <= AXI_05_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_05_arvalid <= AXI_05_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(5).arvalid;
	hbm_05_rready <= AXI_05_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(5).rready;

	AXI_05_ARREADY <= hbm_05_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(5).arready <= hbm_05_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_05_RDATA_PARITY <= hbm_05_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(5).rdata_parity <= hbm_05_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_05_RDATA <= hbm_05_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(5).rdata <= hbm_05_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_05_RID <= hbm_05_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(5).rid <= hbm_05_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_05_RLAST <= hbm_05_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(5).rlast <= hbm_05_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_05_RRESP <= hbm_05_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(5).rresp <= hbm_05_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_05_RVALID <= hbm_05_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(5).rvalid <= hbm_05_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_05_awaddr <= AXI_05_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(5).awaddr);
	hbm_05_awburst <= AXI_05_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_05_awid <= AXI_05_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(5).awid;
	hbm_05_awlen <= AXI_05_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(5).awlen;
	hbm_05_awsize <= AXI_05_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_05_awvalid <= AXI_05_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(5).awvalid;
	hbm_05_wdata <= AXI_05_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(5).wdata;
	hbm_05_wlast <= AXI_05_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(5).wlast;
	hbm_05_wstrb <= AXI_05_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_05_wdata_parity <= AXI_05_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(5).wdata_parity;
	hbm_05_wvalid <= AXI_05_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(5).wvalid;
	hbm_05_bready <= AXI_05_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(5).bready;

	AXI_05_AWREADY <= hbm_05_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(5).awready <= hbm_05_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_05_WREADY <= hbm_05_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(5).wready <= hbm_05_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_05_BID <= hbm_05_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(5).bid <= hbm_05_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_05_BRESP <= hbm_05_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(5).bresp <= hbm_05_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_05_BVALID <= hbm_05_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(5).bvalid <= hbm_05_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_06 --------------------
	hbm_06_araddr <= AXI_06_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(6).araddr);
	hbm_06_arburst <= AXI_06_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_06_arid <= AXI_06_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(6).arid;
	hbm_06_arlen <= AXI_06_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(6).arlen;
	hbm_06_arsize <= AXI_06_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_06_arvalid <= AXI_06_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(6).arvalid;
	hbm_06_rready <= AXI_06_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(6).rready;

	AXI_06_ARREADY <= hbm_06_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(6).arready <= hbm_06_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_06_RDATA_PARITY <= hbm_06_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(6).rdata_parity <= hbm_06_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_06_RDATA <= hbm_06_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(6).rdata <= hbm_06_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_06_RID <= hbm_06_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(6).rid <= hbm_06_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_06_RLAST <= hbm_06_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(6).rlast <= hbm_06_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_06_RRESP <= hbm_06_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(6).rresp <= hbm_06_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_06_RVALID <= hbm_06_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(6).rvalid <= hbm_06_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_06_awaddr <= AXI_06_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(6).awaddr);
	hbm_06_awburst <= AXI_06_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_06_awid <= AXI_06_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(6).awid;
	hbm_06_awlen <= AXI_06_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(6).awlen;
	hbm_06_awsize <= AXI_06_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_06_awvalid <= AXI_06_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(6).awvalid;
	hbm_06_wdata <= AXI_06_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(6).wdata;
	hbm_06_wlast <= AXI_06_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(6).wlast;
	hbm_06_wstrb <= AXI_06_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_06_wdata_parity <= AXI_06_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(6).wdata_parity;
	hbm_06_wvalid <= AXI_06_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(6).wvalid;
	hbm_06_bready <= AXI_06_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(6).bready;

	AXI_06_AWREADY <= hbm_06_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(6).awready <= hbm_06_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_06_WREADY <= hbm_06_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(6).wready <= hbm_06_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_06_BID <= hbm_06_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(6).bid <= hbm_06_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_06_BRESP <= hbm_06_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(6).bresp <= hbm_06_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_06_BVALID <= hbm_06_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(6).bvalid <= hbm_06_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_07 --------------------
	hbm_07_araddr <= AXI_07_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(7).araddr);
	hbm_07_arburst <= AXI_07_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_07_arid <= AXI_07_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(7).arid;
	hbm_07_arlen <= AXI_07_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(7).arlen;
	hbm_07_arsize <= AXI_07_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_07_arvalid <= AXI_07_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(7).arvalid;
	hbm_07_rready <= AXI_07_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(7).rready;

	AXI_07_ARREADY <= hbm_07_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(7).arready <= hbm_07_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_07_RDATA_PARITY <= hbm_07_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(7).rdata_parity <= hbm_07_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_07_RDATA <= hbm_07_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(7).rdata <= hbm_07_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_07_RID <= hbm_07_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(7).rid <= hbm_07_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_07_RLAST <= hbm_07_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(7).rlast <= hbm_07_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_07_RRESP <= hbm_07_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(7).rresp <= hbm_07_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_07_RVALID <= hbm_07_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(7).rvalid <= hbm_07_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_07_awaddr <= AXI_07_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(7).awaddr);
	hbm_07_awburst <= AXI_07_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_07_awid <= AXI_07_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(7).awid;
	hbm_07_awlen <= AXI_07_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(7).awlen;
	hbm_07_awsize <= AXI_07_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_07_awvalid <= AXI_07_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(7).awvalid;
	hbm_07_wdata <= AXI_07_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(7).wdata;
	hbm_07_wlast <= AXI_07_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(7).wlast;
	hbm_07_wstrb <= AXI_07_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_07_wdata_parity <= AXI_07_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(7).wdata_parity;
	hbm_07_wvalid <= AXI_07_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(7).wvalid;
	hbm_07_bready <= AXI_07_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(7).bready;

	AXI_07_AWREADY <= hbm_07_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(7).awready <= hbm_07_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_07_WREADY <= hbm_07_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(7).wready <= hbm_07_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_07_BID <= hbm_07_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(7).bid <= hbm_07_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_07_BRESP <= hbm_07_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(7).bresp <= hbm_07_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_07_BVALID <= hbm_07_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(7).bvalid <= hbm_07_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_08 --------------------
	hbm_08_araddr <= AXI_08_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(8).araddr);
	hbm_08_arburst <= AXI_08_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_08_arid <= AXI_08_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(8).arid;
	hbm_08_arlen <= AXI_08_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(8).arlen;
	hbm_08_arsize <= AXI_08_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_08_arvalid <= AXI_08_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(8).arvalid;
	hbm_08_rready <= AXI_08_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(8).rready;

	AXI_08_ARREADY <= hbm_08_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(8).arready <= hbm_08_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_08_RDATA_PARITY <= hbm_08_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(8).rdata_parity <= hbm_08_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_08_RDATA <= hbm_08_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(8).rdata <= hbm_08_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_08_RID <= hbm_08_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(8).rid <= hbm_08_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_08_RLAST <= hbm_08_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(8).rlast <= hbm_08_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_08_RRESP <= hbm_08_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(8).rresp <= hbm_08_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_08_RVALID <= hbm_08_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(8).rvalid <= hbm_08_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_08_awaddr <= AXI_08_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(8).awaddr);
	hbm_08_awburst <= AXI_08_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_08_awid <= AXI_08_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(8).awid;
	hbm_08_awlen <= AXI_08_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(8).awlen;
	hbm_08_awsize <= AXI_08_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_08_awvalid <= AXI_08_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(8).awvalid;
	hbm_08_wdata <= AXI_08_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(8).wdata;
	hbm_08_wlast <= AXI_08_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(8).wlast;
	hbm_08_wstrb <= AXI_08_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_08_wdata_parity <= AXI_08_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(8).wdata_parity;
	hbm_08_wvalid <= AXI_08_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(8).wvalid;
	hbm_08_bready <= AXI_08_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(8).bready;

	AXI_08_AWREADY <= hbm_08_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(8).awready <= hbm_08_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_08_WREADY <= hbm_08_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(8).wready <= hbm_08_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_08_BID <= hbm_08_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(8).bid <= hbm_08_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_08_BRESP <= hbm_08_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(8).bresp <= hbm_08_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_08_BVALID <= hbm_08_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(8).bvalid <= hbm_08_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_09 --------------------
	hbm_09_araddr <= AXI_09_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(9).araddr);
	hbm_09_arburst <= AXI_09_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_09_arid <= AXI_09_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(9).arid;
	hbm_09_arlen <= AXI_09_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(9).arlen;
	hbm_09_arsize <= AXI_09_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_09_arvalid <= AXI_09_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(9).arvalid;
	hbm_09_rready <= AXI_09_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(9).rready;

	AXI_09_ARREADY <= hbm_09_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(9).arready <= hbm_09_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_09_RDATA_PARITY <= hbm_09_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(9).rdata_parity <= hbm_09_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_09_RDATA <= hbm_09_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(9).rdata <= hbm_09_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_09_RID <= hbm_09_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(9).rid <= hbm_09_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_09_RLAST <= hbm_09_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(9).rlast <= hbm_09_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_09_RRESP <= hbm_09_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(9).rresp <= hbm_09_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_09_RVALID <= hbm_09_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(9).rvalid <= hbm_09_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_09_awaddr <= AXI_09_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(9).awaddr);
	hbm_09_awburst <= AXI_09_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_09_awid <= AXI_09_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(9).awid;
	hbm_09_awlen <= AXI_09_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(9).awlen;
	hbm_09_awsize <= AXI_09_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_09_awvalid <= AXI_09_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(9).awvalid;
	hbm_09_wdata <= AXI_09_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(9).wdata;
	hbm_09_wlast <= AXI_09_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(9).wlast;
	hbm_09_wstrb <= AXI_09_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_09_wdata_parity <= AXI_09_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(9).wdata_parity;
	hbm_09_wvalid <= AXI_09_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(9).wvalid;
	hbm_09_bready <= AXI_09_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(9).bready;

	AXI_09_AWREADY <= hbm_09_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(9).awready <= hbm_09_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_09_WREADY <= hbm_09_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(9).wready <= hbm_09_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_09_BID <= hbm_09_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(9).bid <= hbm_09_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_09_BRESP <= hbm_09_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(9).bresp <= hbm_09_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_09_BVALID <= hbm_09_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(9).bvalid <= hbm_09_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_10 --------------------
	hbm_10_araddr <= AXI_10_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(10).araddr);
	hbm_10_arburst <= AXI_10_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_10_arid <= AXI_10_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(10).arid;
	hbm_10_arlen <= AXI_10_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(10).arlen;
	hbm_10_arsize <= AXI_10_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_10_arvalid <= AXI_10_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(10).arvalid;
	hbm_10_rready <= AXI_10_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(10).rready;

	AXI_10_ARREADY <= hbm_10_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(10).arready <= hbm_10_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_10_RDATA_PARITY <= hbm_10_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(10).rdata_parity <= hbm_10_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_10_RDATA <= hbm_10_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(10).rdata <= hbm_10_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_10_RID <= hbm_10_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(10).rid <= hbm_10_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_10_RLAST <= hbm_10_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(10).rlast <= hbm_10_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_10_RRESP <= hbm_10_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(10).rresp <= hbm_10_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_10_RVALID <= hbm_10_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(10).rvalid <= hbm_10_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_10_awaddr <= AXI_10_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(10).awaddr);
	hbm_10_awburst <= AXI_10_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_10_awid <= AXI_10_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(10).awid;
	hbm_10_awlen <= AXI_10_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(10).awlen;
	hbm_10_awsize <= AXI_10_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_10_awvalid <= AXI_10_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(10).awvalid;
	hbm_10_wdata <= AXI_10_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(10).wdata;
	hbm_10_wlast <= AXI_10_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(10).wlast;
	hbm_10_wstrb <= AXI_10_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_10_wdata_parity <= AXI_10_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(10).wdata_parity;
	hbm_10_wvalid <= AXI_10_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(10).wvalid;
	hbm_10_bready <= AXI_10_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(10).bready;

	AXI_10_AWREADY <= hbm_10_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(10).awready <= hbm_10_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_10_WREADY <= hbm_10_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(10).wready <= hbm_10_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_10_BID <= hbm_10_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(10).bid <= hbm_10_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_10_BRESP <= hbm_10_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(10).bresp <= hbm_10_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_10_BVALID <= hbm_10_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(10).bvalid <= hbm_10_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_11 --------------------
	hbm_11_araddr <= AXI_11_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(11).araddr);
	hbm_11_arburst <= AXI_11_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_11_arid <= AXI_11_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(11).arid;
	hbm_11_arlen <= AXI_11_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(11).arlen;
	hbm_11_arsize <= AXI_11_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_11_arvalid <= AXI_11_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(11).arvalid;
	hbm_11_rready <= AXI_11_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(11).rready;

	AXI_11_ARREADY <= hbm_11_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(11).arready <= hbm_11_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_11_RDATA_PARITY <= hbm_11_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(11).rdata_parity <= hbm_11_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_11_RDATA <= hbm_11_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(11).rdata <= hbm_11_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_11_RID <= hbm_11_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(11).rid <= hbm_11_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_11_RLAST <= hbm_11_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(11).rlast <= hbm_11_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_11_RRESP <= hbm_11_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(11).rresp <= hbm_11_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_11_RVALID <= hbm_11_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(11).rvalid <= hbm_11_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_11_awaddr <= AXI_11_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(11).awaddr);
	hbm_11_awburst <= AXI_11_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_11_awid <= AXI_11_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(11).awid;
	hbm_11_awlen <= AXI_11_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(11).awlen;
	hbm_11_awsize <= AXI_11_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_11_awvalid <= AXI_11_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(11).awvalid;
	hbm_11_wdata <= AXI_11_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(11).wdata;
	hbm_11_wlast <= AXI_11_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(11).wlast;
	hbm_11_wstrb <= AXI_11_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_11_wdata_parity <= AXI_11_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(11).wdata_parity;
	hbm_11_wvalid <= AXI_11_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(11).wvalid;
	hbm_11_bready <= AXI_11_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(11).bready;

	AXI_11_AWREADY <= hbm_11_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(11).awready <= hbm_11_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_11_WREADY <= hbm_11_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(11).wready <= hbm_11_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_11_BID <= hbm_11_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(11).bid <= hbm_11_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_11_BRESP <= hbm_11_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(11).bresp <= hbm_11_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_11_BVALID <= hbm_11_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(11).bvalid <= hbm_11_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_12 --------------------
	hbm_12_araddr <= AXI_12_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(12).araddr);
	hbm_12_arburst <= AXI_12_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_12_arid <= AXI_12_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(12).arid;
	hbm_12_arlen <= AXI_12_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(12).arlen;
	hbm_12_arsize <= AXI_12_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_12_arvalid <= AXI_12_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(12).arvalid;
	hbm_12_rready <= AXI_12_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(12).rready;

	AXI_12_ARREADY <= hbm_12_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(12).arready <= hbm_12_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_12_RDATA_PARITY <= hbm_12_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(12).rdata_parity <= hbm_12_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_12_RDATA <= hbm_12_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(12).rdata <= hbm_12_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_12_RID <= hbm_12_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(12).rid <= hbm_12_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_12_RLAST <= hbm_12_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(12).rlast <= hbm_12_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_12_RRESP <= hbm_12_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(12).rresp <= hbm_12_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_12_RVALID <= hbm_12_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(12).rvalid <= hbm_12_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_12_awaddr <= AXI_12_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(12).awaddr);
	hbm_12_awburst <= AXI_12_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_12_awid <= AXI_12_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(12).awid;
	hbm_12_awlen <= AXI_12_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(12).awlen;
	hbm_12_awsize <= AXI_12_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_12_awvalid <= AXI_12_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(12).awvalid;
	hbm_12_wdata <= AXI_12_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(12).wdata;
	hbm_12_wlast <= AXI_12_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(12).wlast;
	hbm_12_wstrb <= AXI_12_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_12_wdata_parity <= AXI_12_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(12).wdata_parity;
	hbm_12_wvalid <= AXI_12_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(12).wvalid;
	hbm_12_bready <= AXI_12_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(12).bready;

	AXI_12_AWREADY <= hbm_12_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(12).awready <= hbm_12_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_12_WREADY <= hbm_12_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(12).wready <= hbm_12_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_12_BID <= hbm_12_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(12).bid <= hbm_12_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_12_BRESP <= hbm_12_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(12).bresp <= hbm_12_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_12_BVALID <= hbm_12_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(12).bvalid <= hbm_12_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_13 --------------------
	hbm_13_araddr <= AXI_13_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(13).araddr);
	hbm_13_arburst <= AXI_13_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_13_arid <= AXI_13_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(13).arid;
	hbm_13_arlen <= AXI_13_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(13).arlen;
	hbm_13_arsize <= AXI_13_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_13_arvalid <= AXI_13_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(13).arvalid;
	hbm_13_rready <= AXI_13_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(13).rready;

	AXI_13_ARREADY <= hbm_13_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(13).arready <= hbm_13_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_13_RDATA_PARITY <= hbm_13_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(13).rdata_parity <= hbm_13_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_13_RDATA <= hbm_13_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(13).rdata <= hbm_13_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_13_RID <= hbm_13_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(13).rid <= hbm_13_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_13_RLAST <= hbm_13_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(13).rlast <= hbm_13_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_13_RRESP <= hbm_13_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(13).rresp <= hbm_13_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_13_RVALID <= hbm_13_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(13).rvalid <= hbm_13_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_13_awaddr <= AXI_13_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(13).awaddr);
	hbm_13_awburst <= AXI_13_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_13_awid <= AXI_13_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(13).awid;
	hbm_13_awlen <= AXI_13_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(13).awlen;
	hbm_13_awsize <= AXI_13_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_13_awvalid <= AXI_13_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(13).awvalid;
	hbm_13_wdata <= AXI_13_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(13).wdata;
	hbm_13_wlast <= AXI_13_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(13).wlast;
	hbm_13_wstrb <= AXI_13_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_13_wdata_parity <= AXI_13_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(13).wdata_parity;
	hbm_13_wvalid <= AXI_13_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(13).wvalid;
	hbm_13_bready <= AXI_13_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(13).bready;

	AXI_13_AWREADY <= hbm_13_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(13).awready <= hbm_13_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_13_WREADY <= hbm_13_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(13).wready <= hbm_13_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_13_BID <= hbm_13_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(13).bid <= hbm_13_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_13_BRESP <= hbm_13_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(13).bresp <= hbm_13_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_13_BVALID <= hbm_13_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(13).bvalid <= hbm_13_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_14 --------------------
	hbm_14_araddr <= AXI_14_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(14).araddr);
	hbm_14_arburst <= AXI_14_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_14_arid <= AXI_14_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(14).arid;
	hbm_14_arlen <= AXI_14_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(14).arlen;
	hbm_14_arsize <= AXI_14_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_14_arvalid <= AXI_14_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(14).arvalid;
	hbm_14_rready <= AXI_14_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(14).rready;

	AXI_14_ARREADY <= hbm_14_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(14).arready <= hbm_14_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_14_RDATA_PARITY <= hbm_14_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(14).rdata_parity <= hbm_14_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_14_RDATA <= hbm_14_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(14).rdata <= hbm_14_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_14_RID <= hbm_14_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(14).rid <= hbm_14_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_14_RLAST <= hbm_14_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(14).rlast <= hbm_14_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_14_RRESP <= hbm_14_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(14).rresp <= hbm_14_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_14_RVALID <= hbm_14_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(14).rvalid <= hbm_14_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_14_awaddr <= AXI_14_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(14).awaddr);
	hbm_14_awburst <= AXI_14_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_14_awid <= AXI_14_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(14).awid;
	hbm_14_awlen <= AXI_14_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(14).awlen;
	hbm_14_awsize <= AXI_14_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_14_awvalid <= AXI_14_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(14).awvalid;
	hbm_14_wdata <= AXI_14_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(14).wdata;
	hbm_14_wlast <= AXI_14_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(14).wlast;
	hbm_14_wstrb <= AXI_14_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_14_wdata_parity <= AXI_14_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(14).wdata_parity;
	hbm_14_wvalid <= AXI_14_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(14).wvalid;
	hbm_14_bready <= AXI_14_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(14).bready;

	AXI_14_AWREADY <= hbm_14_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(14).awready <= hbm_14_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_14_WREADY <= hbm_14_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(14).wready <= hbm_14_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_14_BID <= hbm_14_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(14).bid <= hbm_14_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_14_BRESP <= hbm_14_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(14).bresp <= hbm_14_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_14_BVALID <= hbm_14_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(14).bvalid <= hbm_14_bvalid when HBM_RW_SELECT(0)='1' else '0';


	-- -------------------- AXI_15 --------------------
	hbm_15_araddr <= AXI_15_ARADDR when HBM_RW_SELECT(1)='0' else std_logic_vector(i_read_pkgs(15).araddr);
	hbm_15_arburst <= AXI_15_ARBURST when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstmode);
	hbm_15_arid <= AXI_15_ARID when HBM_RW_SELECT(1)='0' else i_read_pkgs(15).arid;
	hbm_15_arlen <= AXI_15_ARLEN when HBM_RW_SELECT(1)='0' else i_read_pkgs(15).arlen;
	hbm_15_arsize <= AXI_15_ARSIZE when HBM_RW_SELECT(1)='0' else std_logic_vector(hbm_burstsize);
	hbm_15_arvalid <= AXI_15_ARVALID when HBM_RW_SELECT(1)='0' else i_read_pkgs(15).arvalid;
	hbm_15_rready <= AXI_15_RREADY when HBM_RW_SELECT(1)='0' else i_read_pkgs(15).rready;

	AXI_15_ARREADY <= hbm_15_arready when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(15).arready <= hbm_15_arready when HBM_RW_SELECT(1)='1' else '0';
	AXI_15_RDATA_PARITY <= hbm_15_rdata_parity when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(15).rdata_parity <= hbm_15_rdata_parity when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_15_RDATA <= hbm_15_rdata when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(15).rdata <= hbm_15_rdata when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_15_RID <= hbm_15_rid when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(15).rid <= hbm_15_rid when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_15_RLAST <= hbm_15_rlast when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(15).rlast <= hbm_15_rlast when HBM_RW_SELECT(1)='1' else '0';
	AXI_15_RRESP <= hbm_15_rresp when HBM_RW_SELECT(1)='0' else (others => '0');
	o_read_pkgs(15).rresp <= hbm_15_rresp when HBM_RW_SELECT(1)='1' else (others => '0');
	AXI_15_RVALID <= hbm_15_rvalid when HBM_RW_SELECT(1)='0' else '0';
	o_read_pkgs(15).rvalid <= hbm_15_rvalid when HBM_RW_SELECT(1)='1' else '0';

	hbm_15_awaddr <= AXI_15_AWADDR when HBM_RW_SELECT(0)='0' else std_logic_vector(i_write_pkgs(15).awaddr);
	hbm_15_awburst <= AXI_15_AWBURST when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstmode);
	hbm_15_awid <= AXI_15_AWID when HBM_RW_SELECT(0)='0' else i_write_pkgs(15).awid;
	hbm_15_awlen <= AXI_15_AWLEN when HBM_RW_SELECT(0)='0' else i_write_pkgs(15).awlen;
	hbm_15_awsize <= AXI_15_AWSIZE when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_burstsize);
	hbm_15_awvalid <= AXI_15_AWVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(15).awvalid;
	hbm_15_wdata <= AXI_15_WDATA when HBM_RW_SELECT(0)='0' else i_write_pkgs(15).wdata;
	hbm_15_wlast <= AXI_15_WLAST when HBM_RW_SELECT(0)='0' else i_write_pkgs(15).wlast;
	hbm_15_wstrb <= AXI_15_WSTRB when HBM_RW_SELECT(0)='0' else std_logic_vector(hbm_strobe_setting);
	hbm_15_wdata_parity <= AXI_15_WDATA_PARITY when HBM_RW_SELECT(0)='0' else i_write_pkgs(15).wdata_parity;
	hbm_15_wvalid <= AXI_15_WVALID when HBM_RW_SELECT(0)='0' else i_write_pkgs(15).wvalid;
	hbm_15_bready <= AXI_15_BREADY when HBM_RW_SELECT(0)='0' else i_write_pkgs(15).bready;

	AXI_15_AWREADY <= hbm_15_awready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(15).awready <= hbm_15_awready when HBM_RW_SELECT(0)='1' else '0';
	AXI_15_WREADY <= hbm_15_wready when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(15).wready <= hbm_15_wready when HBM_RW_SELECT(0)='1' else '0';
	AXI_15_BID <= hbm_15_bid when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(15).bid <= hbm_15_bid when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_15_BRESP <= hbm_15_bresp when HBM_RW_SELECT(0)='0' else (others => '0');
	o_write_pkgs(15).bresp <= hbm_15_bresp when HBM_RW_SELECT(0)='1' else (others => '0');
	AXI_15_BVALID <= hbm_15_bvalid when HBM_RW_SELECT(0)='0' else '0';
	o_write_pkgs(15).bvalid <= hbm_15_bvalid when HBM_RW_SELECT(0)='1' else '0';

	-- ==================================================
	-- HOST-ONLY DIRECT CONNECT (HBM <-> HOST), TFHE DISABLED
	-- ==================================================

	-- -- -------------------- AXI_00 --------------------
	-- hbm_00_araddr <= AXI_00_ARADDR;
	-- hbm_00_arburst <= AXI_00_ARBURST;
	-- hbm_00_arid <= AXI_00_ARID;
	-- hbm_00_arlen <= AXI_00_ARLEN;
	-- hbm_00_arsize <= AXI_00_ARSIZE;
	-- hbm_00_arvalid <= AXI_00_ARVALID;
	-- hbm_00_rready <= AXI_00_RREADY;
	-- hbm_00_awaddr <= AXI_00_AWADDR;
	-- hbm_00_awburst <= AXI_00_AWBURST;
	-- hbm_00_awid <= AXI_00_AWID;
	-- hbm_00_awlen <= AXI_00_AWLEN;
	-- hbm_00_awsize <= AXI_00_AWSIZE;
	-- hbm_00_awvalid <= AXI_00_AWVALID;
	-- hbm_00_wdata <= AXI_00_WDATA;
	-- hbm_00_wlast <= AXI_00_WLAST;
	-- hbm_00_wstrb <= AXI_00_WSTRB;
	-- hbm_00_wdata_parity <= AXI_00_WDATA_PARITY;
	-- hbm_00_wvalid <= AXI_00_WVALID;
	-- hbm_00_bready <= AXI_00_BREADY;

	-- AXI_00_ARREADY <= hbm_00_arready;
	-- AXI_00_RDATA_PARITY <= hbm_00_rdata_parity;
	-- AXI_00_RDATA <= hbm_00_rdata;
	-- AXI_00_RID <= hbm_00_rid;
	-- AXI_00_RLAST <= hbm_00_rlast;
	-- AXI_00_RRESP <= hbm_00_rresp;
	-- AXI_00_RVALID <= hbm_00_rvalid;
	-- AXI_00_AWREADY <= hbm_00_awready;
	-- AXI_00_WREADY <= hbm_00_wready;
	-- AXI_00_BID <= hbm_00_bid;
	-- AXI_00_BRESP <= hbm_00_bresp;
	-- AXI_00_BVALID <= hbm_00_bvalid;

	-- o_read_pkgs(0).arready <= '0';
	-- o_read_pkgs(0).rdata_parity <= (others => '0');
	-- o_read_pkgs(0).rdata <= (others => '0');
	-- o_read_pkgs(0).rid <= (others => '0');
	-- o_read_pkgs(0).rlast <= '0';
	-- o_read_pkgs(0).rresp <= (others => '0');
	-- o_read_pkgs(0).rvalid <= '0';
	-- o_write_pkgs(0).awready <= '0';
	-- o_write_pkgs(0).wready <= '0';
	-- o_write_pkgs(0).bid <= (others => '0');
	-- o_write_pkgs(0).bresp <= (others => '0');
	-- o_write_pkgs(0).bvalid <= '0';


	-- -- -------------------- AXI_01 --------------------
	-- hbm_01_araddr <= AXI_01_ARADDR;
	-- hbm_01_arburst <= AXI_01_ARBURST;
	-- hbm_01_arid <= AXI_01_ARID;
	-- hbm_01_arlen <= AXI_01_ARLEN;
	-- hbm_01_arsize <= AXI_01_ARSIZE;
	-- hbm_01_arvalid <= AXI_01_ARVALID;
	-- hbm_01_rready <= AXI_01_RREADY;
	-- hbm_01_awaddr <= AXI_01_AWADDR;
	-- hbm_01_awburst <= AXI_01_AWBURST;
	-- hbm_01_awid <= AXI_01_AWID;
	-- hbm_01_awlen <= AXI_01_AWLEN;
	-- hbm_01_awsize <= AXI_01_AWSIZE;
	-- hbm_01_awvalid <= AXI_01_AWVALID;
	-- hbm_01_wdata <= AXI_01_WDATA;
	-- hbm_01_wlast <= AXI_01_WLAST;
	-- hbm_01_wstrb <= AXI_01_WSTRB;
	-- hbm_01_wdata_parity <= AXI_01_WDATA_PARITY;
	-- hbm_01_wvalid <= AXI_01_WVALID;
	-- hbm_01_bready <= AXI_01_BREADY;

	-- AXI_01_ARREADY <= hbm_01_arready;
	-- AXI_01_RDATA_PARITY <= hbm_01_rdata_parity;
	-- AXI_01_RDATA <= hbm_01_rdata;
	-- AXI_01_RID <= hbm_01_rid;
	-- AXI_01_RLAST <= hbm_01_rlast;
	-- AXI_01_RRESP <= hbm_01_rresp;
	-- AXI_01_RVALID <= hbm_01_rvalid;
	-- AXI_01_AWREADY <= hbm_01_awready;
	-- AXI_01_WREADY <= hbm_01_wready;
	-- AXI_01_BID <= hbm_01_bid;
	-- AXI_01_BRESP <= hbm_01_bresp;
	-- AXI_01_BVALID <= hbm_01_bvalid;

	-- o_read_pkgs(1).arready <= '0';
	-- o_read_pkgs(1).rdata_parity <= (others => '0');
	-- o_read_pkgs(1).rdata <= (others => '0');
	-- o_read_pkgs(1).rid <= (others => '0');
	-- o_read_pkgs(1).rlast <= '0';
	-- o_read_pkgs(1).rresp <= (others => '0');
	-- o_read_pkgs(1).rvalid <= '0';
	-- o_write_pkgs(1).awready <= '0';
	-- o_write_pkgs(1).wready <= '0';
	-- o_write_pkgs(1).bid <= (others => '0');
	-- o_write_pkgs(1).bresp <= (others => '0');
	-- o_write_pkgs(1).bvalid <= '0';


	-- -- -------------------- AXI_02 --------------------
	-- hbm_02_araddr <= AXI_02_ARADDR;
	-- hbm_02_arburst <= AXI_02_ARBURST;
	-- hbm_02_arid <= AXI_02_ARID;
	-- hbm_02_arlen <= AXI_02_ARLEN;
	-- hbm_02_arsize <= AXI_02_ARSIZE;
	-- hbm_02_arvalid <= AXI_02_ARVALID;
	-- hbm_02_rready <= AXI_02_RREADY;
	-- hbm_02_awaddr <= AXI_02_AWADDR;
	-- hbm_02_awburst <= AXI_02_AWBURST;
	-- hbm_02_awid <= AXI_02_AWID;
	-- hbm_02_awlen <= AXI_02_AWLEN;
	-- hbm_02_awsize <= AXI_02_AWSIZE;
	-- hbm_02_awvalid <= AXI_02_AWVALID;
	-- hbm_02_wdata <= AXI_02_WDATA;
	-- hbm_02_wlast <= AXI_02_WLAST;
	-- hbm_02_wstrb <= AXI_02_WSTRB;
	-- hbm_02_wdata_parity <= AXI_02_WDATA_PARITY;
	-- hbm_02_wvalid <= AXI_02_WVALID;
	-- hbm_02_bready <= AXI_02_BREADY;

	-- AXI_02_ARREADY <= hbm_02_arready;
	-- AXI_02_RDATA_PARITY <= hbm_02_rdata_parity;
	-- AXI_02_RDATA <= hbm_02_rdata;
	-- AXI_02_RID <= hbm_02_rid;
	-- AXI_02_RLAST <= hbm_02_rlast;
	-- AXI_02_RRESP <= hbm_02_rresp;
	-- AXI_02_RVALID <= hbm_02_rvalid;
	-- AXI_02_AWREADY <= hbm_02_awready;
	-- AXI_02_WREADY <= hbm_02_wready;
	-- AXI_02_BID <= hbm_02_bid;
	-- AXI_02_BRESP <= hbm_02_bresp;
	-- AXI_02_BVALID <= hbm_02_bvalid;

	-- o_read_pkgs(2).arready <= '0';
	-- o_read_pkgs(2).rdata_parity <= (others => '0');
	-- o_read_pkgs(2).rdata <= (others => '0');
	-- o_read_pkgs(2).rid <= (others => '0');
	-- o_read_pkgs(2).rlast <= '0';
	-- o_read_pkgs(2).rresp <= (others => '0');
	-- o_read_pkgs(2).rvalid <= '0';
	-- o_write_pkgs(2).awready <= '0';
	-- o_write_pkgs(2).wready <= '0';
	-- o_write_pkgs(2).bid <= (others => '0');
	-- o_write_pkgs(2).bresp <= (others => '0');
	-- o_write_pkgs(2).bvalid <= '0';


	-- -- -------------------- AXI_03 --------------------
	-- hbm_03_araddr <= AXI_03_ARADDR;
	-- hbm_03_arburst <= AXI_03_ARBURST;
	-- hbm_03_arid <= AXI_03_ARID;
	-- hbm_03_arlen <= AXI_03_ARLEN;
	-- hbm_03_arsize <= AXI_03_ARSIZE;
	-- hbm_03_arvalid <= AXI_03_ARVALID;
	-- hbm_03_rready <= AXI_03_RREADY;
	-- hbm_03_awaddr <= AXI_03_AWADDR;
	-- hbm_03_awburst <= AXI_03_AWBURST;
	-- hbm_03_awid <= AXI_03_AWID;
	-- hbm_03_awlen <= AXI_03_AWLEN;
	-- hbm_03_awsize <= AXI_03_AWSIZE;
	-- hbm_03_awvalid <= AXI_03_AWVALID;
	-- hbm_03_wdata <= AXI_03_WDATA;
	-- hbm_03_wlast <= AXI_03_WLAST;
	-- hbm_03_wstrb <= AXI_03_WSTRB;
	-- hbm_03_wdata_parity <= AXI_03_WDATA_PARITY;
	-- hbm_03_wvalid <= AXI_03_WVALID;
	-- hbm_03_bready <= AXI_03_BREADY;

	-- AXI_03_ARREADY <= hbm_03_arready;
	-- AXI_03_RDATA_PARITY <= hbm_03_rdata_parity;
	-- AXI_03_RDATA <= hbm_03_rdata;
	-- AXI_03_RID <= hbm_03_rid;
	-- AXI_03_RLAST <= hbm_03_rlast;
	-- AXI_03_RRESP <= hbm_03_rresp;
	-- AXI_03_RVALID <= hbm_03_rvalid;
	-- AXI_03_AWREADY <= hbm_03_awready;
	-- AXI_03_WREADY <= hbm_03_wready;
	-- AXI_03_BID <= hbm_03_bid;
	-- AXI_03_BRESP <= hbm_03_bresp;
	-- AXI_03_BVALID <= hbm_03_bvalid;

	-- o_read_pkgs(3).arready <= '0';
	-- o_read_pkgs(3).rdata_parity <= (others => '0');
	-- o_read_pkgs(3).rdata <= (others => '0');
	-- o_read_pkgs(3).rid <= (others => '0');
	-- o_read_pkgs(3).rlast <= '0';
	-- o_read_pkgs(3).rresp <= (others => '0');
	-- o_read_pkgs(3).rvalid <= '0';
	-- o_write_pkgs(3).awready <= '0';
	-- o_write_pkgs(3).wready <= '0';
	-- o_write_pkgs(3).bid <= (others => '0');
	-- o_write_pkgs(3).bresp <= (others => '0');
	-- o_write_pkgs(3).bvalid <= '0';


	-- -- -------------------- AXI_04 --------------------
	-- hbm_04_araddr <= AXI_04_ARADDR;
	-- hbm_04_arburst <= AXI_04_ARBURST;
	-- hbm_04_arid <= AXI_04_ARID;
	-- hbm_04_arlen <= AXI_04_ARLEN;
	-- hbm_04_arsize <= AXI_04_ARSIZE;
	-- hbm_04_arvalid <= AXI_04_ARVALID;
	-- hbm_04_rready <= AXI_04_RREADY;
	-- hbm_04_awaddr <= AXI_04_AWADDR;
	-- hbm_04_awburst <= AXI_04_AWBURST;
	-- hbm_04_awid <= AXI_04_AWID;
	-- hbm_04_awlen <= AXI_04_AWLEN;
	-- hbm_04_awsize <= AXI_04_AWSIZE;
	-- hbm_04_awvalid <= AXI_04_AWVALID;
	-- hbm_04_wdata <= AXI_04_WDATA;
	-- hbm_04_wlast <= AXI_04_WLAST;
	-- hbm_04_wstrb <= AXI_04_WSTRB;
	-- hbm_04_wdata_parity <= AXI_04_WDATA_PARITY;
	-- hbm_04_wvalid <= AXI_04_WVALID;
	-- hbm_04_bready <= AXI_04_BREADY;

	-- AXI_04_ARREADY <= hbm_04_arready;
	-- AXI_04_RDATA_PARITY <= hbm_04_rdata_parity;
	-- AXI_04_RDATA <= hbm_04_rdata;
	-- AXI_04_RID <= hbm_04_rid;
	-- AXI_04_RLAST <= hbm_04_rlast;
	-- AXI_04_RRESP <= hbm_04_rresp;
	-- AXI_04_RVALID <= hbm_04_rvalid;
	-- AXI_04_AWREADY <= hbm_04_awready;
	-- AXI_04_WREADY <= hbm_04_wready;
	-- AXI_04_BID <= hbm_04_bid;
	-- AXI_04_BRESP <= hbm_04_bresp;
	-- AXI_04_BVALID <= hbm_04_bvalid;

	-- o_read_pkgs(4).arready <= '0';
	-- o_read_pkgs(4).rdata_parity <= (others => '0');
	-- o_read_pkgs(4).rdata <= (others => '0');
	-- o_read_pkgs(4).rid <= (others => '0');
	-- o_read_pkgs(4).rlast <= '0';
	-- o_read_pkgs(4).rresp <= (others => '0');
	-- o_read_pkgs(4).rvalid <= '0';
	-- o_write_pkgs(4).awready <= '0';
	-- o_write_pkgs(4).wready <= '0';
	-- o_write_pkgs(4).bid <= (others => '0');
	-- o_write_pkgs(4).bresp <= (others => '0');
	-- o_write_pkgs(4).bvalid <= '0';


	-- -- -------------------- AXI_05 --------------------
	-- hbm_05_araddr <= AXI_05_ARADDR;
	-- hbm_05_arburst <= AXI_05_ARBURST;
	-- hbm_05_arid <= AXI_05_ARID;
	-- hbm_05_arlen <= AXI_05_ARLEN;
	-- hbm_05_arsize <= AXI_05_ARSIZE;
	-- hbm_05_arvalid <= AXI_05_ARVALID;
	-- hbm_05_rready <= AXI_05_RREADY;
	-- hbm_05_awaddr <= AXI_05_AWADDR;
	-- hbm_05_awburst <= AXI_05_AWBURST;
	-- hbm_05_awid <= AXI_05_AWID;
	-- hbm_05_awlen <= AXI_05_AWLEN;
	-- hbm_05_awsize <= AXI_05_AWSIZE;
	-- hbm_05_awvalid <= AXI_05_AWVALID;
	-- hbm_05_wdata <= AXI_05_WDATA;
	-- hbm_05_wlast <= AXI_05_WLAST;
	-- hbm_05_wstrb <= AXI_05_WSTRB;
	-- hbm_05_wdata_parity <= AXI_05_WDATA_PARITY;
	-- hbm_05_wvalid <= AXI_05_WVALID;
	-- hbm_05_bready <= AXI_05_BREADY;

	-- AXI_05_ARREADY <= hbm_05_arready;
	-- AXI_05_RDATA_PARITY <= hbm_05_rdata_parity;
	-- AXI_05_RDATA <= hbm_05_rdata;
	-- AXI_05_RID <= hbm_05_rid;
	-- AXI_05_RLAST <= hbm_05_rlast;
	-- AXI_05_RRESP <= hbm_05_rresp;
	-- AXI_05_RVALID <= hbm_05_rvalid;
	-- AXI_05_AWREADY <= hbm_05_awready;
	-- AXI_05_WREADY <= hbm_05_wready;
	-- AXI_05_BID <= hbm_05_bid;
	-- AXI_05_BRESP <= hbm_05_bresp;
	-- AXI_05_BVALID <= hbm_05_bvalid;

	-- o_read_pkgs(5).arready <= '0';
	-- o_read_pkgs(5).rdata_parity <= (others => '0');
	-- o_read_pkgs(5).rdata <= (others => '0');
	-- o_read_pkgs(5).rid <= (others => '0');
	-- o_read_pkgs(5).rlast <= '0';
	-- o_read_pkgs(5).rresp <= (others => '0');
	-- o_read_pkgs(5).rvalid <= '0';
	-- o_write_pkgs(5).awready <= '0';
	-- o_write_pkgs(5).wready <= '0';
	-- o_write_pkgs(5).bid <= (others => '0');
	-- o_write_pkgs(5).bresp <= (others => '0');
	-- o_write_pkgs(5).bvalid <= '0';


	-- -- -------------------- AXI_06 --------------------
	-- hbm_06_araddr <= AXI_06_ARADDR;
	-- hbm_06_arburst <= AXI_06_ARBURST;
	-- hbm_06_arid <= AXI_06_ARID;
	-- hbm_06_arlen <= AXI_06_ARLEN;
	-- hbm_06_arsize <= AXI_06_ARSIZE;
	-- hbm_06_arvalid <= AXI_06_ARVALID;
	-- hbm_06_rready <= AXI_06_RREADY;
	-- hbm_06_awaddr <= AXI_06_AWADDR;
	-- hbm_06_awburst <= AXI_06_AWBURST;
	-- hbm_06_awid <= AXI_06_AWID;
	-- hbm_06_awlen <= AXI_06_AWLEN;
	-- hbm_06_awsize <= AXI_06_AWSIZE;
	-- hbm_06_awvalid <= AXI_06_AWVALID;
	-- hbm_06_wdata <= AXI_06_WDATA;
	-- hbm_06_wlast <= AXI_06_WLAST;
	-- hbm_06_wstrb <= AXI_06_WSTRB;
	-- hbm_06_wdata_parity <= AXI_06_WDATA_PARITY;
	-- hbm_06_wvalid <= AXI_06_WVALID;
	-- hbm_06_bready <= AXI_06_BREADY;

	-- AXI_06_ARREADY <= hbm_06_arready;
	-- AXI_06_RDATA_PARITY <= hbm_06_rdata_parity;
	-- AXI_06_RDATA <= hbm_06_rdata;
	-- AXI_06_RID <= hbm_06_rid;
	-- AXI_06_RLAST <= hbm_06_rlast;
	-- AXI_06_RRESP <= hbm_06_rresp;
	-- AXI_06_RVALID <= hbm_06_rvalid;
	-- AXI_06_AWREADY <= hbm_06_awready;
	-- AXI_06_WREADY <= hbm_06_wready;
	-- AXI_06_BID <= hbm_06_bid;
	-- AXI_06_BRESP <= hbm_06_bresp;
	-- AXI_06_BVALID <= hbm_06_bvalid;

	-- o_read_pkgs(6).arready <= '0';
	-- o_read_pkgs(6).rdata_parity <= (others => '0');
	-- o_read_pkgs(6).rdata <= (others => '0');
	-- o_read_pkgs(6).rid <= (others => '0');
	-- o_read_pkgs(6).rlast <= '0';
	-- o_read_pkgs(6).rresp <= (others => '0');
	-- o_read_pkgs(6).rvalid <= '0';
	-- o_write_pkgs(6).awready <= '0';
	-- o_write_pkgs(6).wready <= '0';
	-- o_write_pkgs(6).bid <= (others => '0');
	-- o_write_pkgs(6).bresp <= (others => '0');
	-- o_write_pkgs(6).bvalid <= '0';


	-- -- -------------------- AXI_07 --------------------
	-- hbm_07_araddr <= AXI_07_ARADDR;
	-- hbm_07_arburst <= AXI_07_ARBURST;
	-- hbm_07_arid <= AXI_07_ARID;
	-- hbm_07_arlen <= AXI_07_ARLEN;
	-- hbm_07_arsize <= AXI_07_ARSIZE;
	-- hbm_07_arvalid <= AXI_07_ARVALID;
	-- hbm_07_rready <= AXI_07_RREADY;
	-- hbm_07_awaddr <= AXI_07_AWADDR;
	-- hbm_07_awburst <= AXI_07_AWBURST;
	-- hbm_07_awid <= AXI_07_AWID;
	-- hbm_07_awlen <= AXI_07_AWLEN;
	-- hbm_07_awsize <= AXI_07_AWSIZE;
	-- hbm_07_awvalid <= AXI_07_AWVALID;
	-- hbm_07_wdata <= AXI_07_WDATA;
	-- hbm_07_wlast <= AXI_07_WLAST;
	-- hbm_07_wstrb <= AXI_07_WSTRB;
	-- hbm_07_wdata_parity <= AXI_07_WDATA_PARITY;
	-- hbm_07_wvalid <= AXI_07_WVALID;
	-- hbm_07_bready <= AXI_07_BREADY;

	-- AXI_07_ARREADY <= hbm_07_arready;
	-- AXI_07_RDATA_PARITY <= hbm_07_rdata_parity;
	-- AXI_07_RDATA <= hbm_07_rdata;
	-- AXI_07_RID <= hbm_07_rid;
	-- AXI_07_RLAST <= hbm_07_rlast;
	-- AXI_07_RRESP <= hbm_07_rresp;
	-- AXI_07_RVALID <= hbm_07_rvalid;
	-- AXI_07_AWREADY <= hbm_07_awready;
	-- AXI_07_WREADY <= hbm_07_wready;
	-- AXI_07_BID <= hbm_07_bid;
	-- AXI_07_BRESP <= hbm_07_bresp;
	-- AXI_07_BVALID <= hbm_07_bvalid;

	-- o_read_pkgs(7).arready <= '0';
	-- o_read_pkgs(7).rdata_parity <= (others => '0');
	-- o_read_pkgs(7).rdata <= (others => '0');
	-- o_read_pkgs(7).rid <= (others => '0');
	-- o_read_pkgs(7).rlast <= '0';
	-- o_read_pkgs(7).rresp <= (others => '0');
	-- o_read_pkgs(7).rvalid <= '0';
	-- o_write_pkgs(7).awready <= '0';
	-- o_write_pkgs(7).wready <= '0';
	-- o_write_pkgs(7).bid <= (others => '0');
	-- o_write_pkgs(7).bresp <= (others => '0');
	-- o_write_pkgs(7).bvalid <= '0';


	-- -- -------------------- AXI_08 --------------------
	-- hbm_08_araddr <= AXI_08_ARADDR;
	-- hbm_08_arburst <= AXI_08_ARBURST;
	-- hbm_08_arid <= AXI_08_ARID;
	-- hbm_08_arlen <= AXI_08_ARLEN;
	-- hbm_08_arsize <= AXI_08_ARSIZE;
	-- hbm_08_arvalid <= AXI_08_ARVALID;
	-- hbm_08_rready <= AXI_08_RREADY;
	-- hbm_08_awaddr <= AXI_08_AWADDR;
	-- hbm_08_awburst <= AXI_08_AWBURST;
	-- hbm_08_awid <= AXI_08_AWID;
	-- hbm_08_awlen <= AXI_08_AWLEN;
	-- hbm_08_awsize <= AXI_08_AWSIZE;
	-- hbm_08_awvalid <= AXI_08_AWVALID;
	-- hbm_08_wdata <= AXI_08_WDATA;
	-- hbm_08_wlast <= AXI_08_WLAST;
	-- hbm_08_wstrb <= AXI_08_WSTRB;
	-- hbm_08_wdata_parity <= AXI_08_WDATA_PARITY;
	-- hbm_08_wvalid <= AXI_08_WVALID;
	-- hbm_08_bready <= AXI_08_BREADY;

	-- AXI_08_ARREADY <= hbm_08_arready;
	-- AXI_08_RDATA_PARITY <= hbm_08_rdata_parity;
	-- AXI_08_RDATA <= hbm_08_rdata;
	-- AXI_08_RID <= hbm_08_rid;
	-- AXI_08_RLAST <= hbm_08_rlast;
	-- AXI_08_RRESP <= hbm_08_rresp;
	-- AXI_08_RVALID <= hbm_08_rvalid;
	-- AXI_08_AWREADY <= hbm_08_awready;
	-- AXI_08_WREADY <= hbm_08_wready;
	-- AXI_08_BID <= hbm_08_bid;
	-- AXI_08_BRESP <= hbm_08_bresp;
	-- AXI_08_BVALID <= hbm_08_bvalid;

	-- o_read_pkgs(8).arready <= '0';
	-- o_read_pkgs(8).rdata_parity <= (others => '0');
	-- o_read_pkgs(8).rdata <= (others => '0');
	-- o_read_pkgs(8).rid <= (others => '0');
	-- o_read_pkgs(8).rlast <= '0';
	-- o_read_pkgs(8).rresp <= (others => '0');
	-- o_read_pkgs(8).rvalid <= '0';
	-- o_write_pkgs(8).awready <= '0';
	-- o_write_pkgs(8).wready <= '0';
	-- o_write_pkgs(8).bid <= (others => '0');
	-- o_write_pkgs(8).bresp <= (others => '0');
	-- o_write_pkgs(8).bvalid <= '0';


	-- -- -------------------- AXI_09 --------------------
	-- hbm_09_araddr <= AXI_09_ARADDR;
	-- hbm_09_arburst <= AXI_09_ARBURST;
	-- hbm_09_arid <= AXI_09_ARID;
	-- hbm_09_arlen <= AXI_09_ARLEN;
	-- hbm_09_arsize <= AXI_09_ARSIZE;
	-- hbm_09_arvalid <= AXI_09_ARVALID;
	-- hbm_09_rready <= AXI_09_RREADY;
	-- hbm_09_awaddr <= AXI_09_AWADDR;
	-- hbm_09_awburst <= AXI_09_AWBURST;
	-- hbm_09_awid <= AXI_09_AWID;
	-- hbm_09_awlen <= AXI_09_AWLEN;
	-- hbm_09_awsize <= AXI_09_AWSIZE;
	-- hbm_09_awvalid <= AXI_09_AWVALID;
	-- hbm_09_wdata <= AXI_09_WDATA;
	-- hbm_09_wlast <= AXI_09_WLAST;
	-- hbm_09_wstrb <= AXI_09_WSTRB;
	-- hbm_09_wdata_parity <= AXI_09_WDATA_PARITY;
	-- hbm_09_wvalid <= AXI_09_WVALID;
	-- hbm_09_bready <= AXI_09_BREADY;

	-- AXI_09_ARREADY <= hbm_09_arready;
	-- AXI_09_RDATA_PARITY <= hbm_09_rdata_parity;
	-- AXI_09_RDATA <= hbm_09_rdata;
	-- AXI_09_RID <= hbm_09_rid;
	-- AXI_09_RLAST <= hbm_09_rlast;
	-- AXI_09_RRESP <= hbm_09_rresp;
	-- AXI_09_RVALID <= hbm_09_rvalid;
	-- AXI_09_AWREADY <= hbm_09_awready;
	-- AXI_09_WREADY <= hbm_09_wready;
	-- AXI_09_BID <= hbm_09_bid;
	-- AXI_09_BRESP <= hbm_09_bresp;
	-- AXI_09_BVALID <= hbm_09_bvalid;

	-- o_read_pkgs(9).arready <= '0';
	-- o_read_pkgs(9).rdata_parity <= (others => '0');
	-- o_read_pkgs(9).rdata <= (others => '0');
	-- o_read_pkgs(9).rid <= (others => '0');
	-- o_read_pkgs(9).rlast <= '0';
	-- o_read_pkgs(9).rresp <= (others => '0');
	-- o_read_pkgs(9).rvalid <= '0';
	-- o_write_pkgs(9).awready <= '0';
	-- o_write_pkgs(9).wready <= '0';
	-- o_write_pkgs(9).bid <= (others => '0');
	-- o_write_pkgs(9).bresp <= (others => '0');
	-- o_write_pkgs(9).bvalid <= '0';


	-- -- -------------------- AXI_10 --------------------
	-- hbm_10_araddr <= AXI_10_ARADDR;
	-- hbm_10_arburst <= AXI_10_ARBURST;
	-- hbm_10_arid <= AXI_10_ARID;
	-- hbm_10_arlen <= AXI_10_ARLEN;
	-- hbm_10_arsize <= AXI_10_ARSIZE;
	-- hbm_10_arvalid <= AXI_10_ARVALID;
	-- hbm_10_rready <= AXI_10_RREADY;
	-- hbm_10_awaddr <= AXI_10_AWADDR;
	-- hbm_10_awburst <= AXI_10_AWBURST;
	-- hbm_10_awid <= AXI_10_AWID;
	-- hbm_10_awlen <= AXI_10_AWLEN;
	-- hbm_10_awsize <= AXI_10_AWSIZE;
	-- hbm_10_awvalid <= AXI_10_AWVALID;
	-- hbm_10_wdata <= AXI_10_WDATA;
	-- hbm_10_wlast <= AXI_10_WLAST;
	-- hbm_10_wstrb <= AXI_10_WSTRB;
	-- hbm_10_wdata_parity <= AXI_10_WDATA_PARITY;
	-- hbm_10_wvalid <= AXI_10_WVALID;
	-- hbm_10_bready <= AXI_10_BREADY;

	-- AXI_10_ARREADY <= hbm_10_arready;
	-- AXI_10_RDATA_PARITY <= hbm_10_rdata_parity;
	-- AXI_10_RDATA <= hbm_10_rdata;
	-- AXI_10_RID <= hbm_10_rid;
	-- AXI_10_RLAST <= hbm_10_rlast;
	-- AXI_10_RRESP <= hbm_10_rresp;
	-- AXI_10_RVALID <= hbm_10_rvalid;
	-- AXI_10_AWREADY <= hbm_10_awready;
	-- AXI_10_WREADY <= hbm_10_wready;
	-- AXI_10_BID <= hbm_10_bid;
	-- AXI_10_BRESP <= hbm_10_bresp;
	-- AXI_10_BVALID <= hbm_10_bvalid;

	-- o_read_pkgs(10).arready <= '0';
	-- o_read_pkgs(10).rdata_parity <= (others => '0');
	-- o_read_pkgs(10).rdata <= (others => '0');
	-- o_read_pkgs(10).rid <= (others => '0');
	-- o_read_pkgs(10).rlast <= '0';
	-- o_read_pkgs(10).rresp <= (others => '0');
	-- o_read_pkgs(10).rvalid <= '0';
	-- o_write_pkgs(10).awready <= '0';
	-- o_write_pkgs(10).wready <= '0';
	-- o_write_pkgs(10).bid <= (others => '0');
	-- o_write_pkgs(10).bresp <= (others => '0');
	-- o_write_pkgs(10).bvalid <= '0';


	-- -- -------------------- AXI_11 --------------------
	-- hbm_11_araddr <= AXI_11_ARADDR;
	-- hbm_11_arburst <= AXI_11_ARBURST;
	-- hbm_11_arid <= AXI_11_ARID;
	-- hbm_11_arlen <= AXI_11_ARLEN;
	-- hbm_11_arsize <= AXI_11_ARSIZE;
	-- hbm_11_arvalid <= AXI_11_ARVALID;
	-- hbm_11_rready <= AXI_11_RREADY;
	-- hbm_11_awaddr <= AXI_11_AWADDR;
	-- hbm_11_awburst <= AXI_11_AWBURST;
	-- hbm_11_awid <= AXI_11_AWID;
	-- hbm_11_awlen <= AXI_11_AWLEN;
	-- hbm_11_awsize <= AXI_11_AWSIZE;
	-- hbm_11_awvalid <= AXI_11_AWVALID;
	-- hbm_11_wdata <= AXI_11_WDATA;
	-- hbm_11_wlast <= AXI_11_WLAST;
	-- hbm_11_wstrb <= AXI_11_WSTRB;
	-- hbm_11_wdata_parity <= AXI_11_WDATA_PARITY;
	-- hbm_11_wvalid <= AXI_11_WVALID;
	-- hbm_11_bready <= AXI_11_BREADY;

	-- AXI_11_ARREADY <= hbm_11_arready;
	-- AXI_11_RDATA_PARITY <= hbm_11_rdata_parity;
	-- AXI_11_RDATA <= hbm_11_rdata;
	-- AXI_11_RID <= hbm_11_rid;
	-- AXI_11_RLAST <= hbm_11_rlast;
	-- AXI_11_RRESP <= hbm_11_rresp;
	-- AXI_11_RVALID <= hbm_11_rvalid;
	-- AXI_11_AWREADY <= hbm_11_awready;
	-- AXI_11_WREADY <= hbm_11_wready;
	-- AXI_11_BID <= hbm_11_bid;
	-- AXI_11_BRESP <= hbm_11_bresp;
	-- AXI_11_BVALID <= hbm_11_bvalid;

	-- o_read_pkgs(11).arready <= '0';
	-- o_read_pkgs(11).rdata_parity <= (others => '0');
	-- o_read_pkgs(11).rdata <= (others => '0');
	-- o_read_pkgs(11).rid <= (others => '0');
	-- o_read_pkgs(11).rlast <= '0';
	-- o_read_pkgs(11).rresp <= (others => '0');
	-- o_read_pkgs(11).rvalid <= '0';
	-- o_write_pkgs(11).awready <= '0';
	-- o_write_pkgs(11).wready <= '0';
	-- o_write_pkgs(11).bid <= (others => '0');
	-- o_write_pkgs(11).bresp <= (others => '0');
	-- o_write_pkgs(11).bvalid <= '0';


	-- -- -------------------- AXI_12 --------------------
	-- hbm_12_araddr <= AXI_12_ARADDR;
	-- hbm_12_arburst <= AXI_12_ARBURST;
	-- hbm_12_arid <= AXI_12_ARID;
	-- hbm_12_arlen <= AXI_12_ARLEN;
	-- hbm_12_arsize <= AXI_12_ARSIZE;
	-- hbm_12_arvalid <= AXI_12_ARVALID;
	-- hbm_12_rready <= AXI_12_RREADY;
	-- hbm_12_awaddr <= AXI_12_AWADDR;
	-- hbm_12_awburst <= AXI_12_AWBURST;
	-- hbm_12_awid <= AXI_12_AWID;
	-- hbm_12_awlen <= AXI_12_AWLEN;
	-- hbm_12_awsize <= AXI_12_AWSIZE;
	-- hbm_12_awvalid <= AXI_12_AWVALID;
	-- hbm_12_wdata <= AXI_12_WDATA;
	-- hbm_12_wlast <= AXI_12_WLAST;
	-- hbm_12_wstrb <= AXI_12_WSTRB;
	-- hbm_12_wdata_parity <= AXI_12_WDATA_PARITY;
	-- hbm_12_wvalid <= AXI_12_WVALID;
	-- hbm_12_bready <= AXI_12_BREADY;

	-- AXI_12_ARREADY <= hbm_12_arready;
	-- AXI_12_RDATA_PARITY <= hbm_12_rdata_parity;
	-- AXI_12_RDATA <= hbm_12_rdata;
	-- AXI_12_RID <= hbm_12_rid;
	-- AXI_12_RLAST <= hbm_12_rlast;
	-- AXI_12_RRESP <= hbm_12_rresp;
	-- AXI_12_RVALID <= hbm_12_rvalid;
	-- AXI_12_AWREADY <= hbm_12_awready;
	-- AXI_12_WREADY <= hbm_12_wready;
	-- AXI_12_BID <= hbm_12_bid;
	-- AXI_12_BRESP <= hbm_12_bresp;
	-- AXI_12_BVALID <= hbm_12_bvalid;

	-- o_read_pkgs(12).arready <= '0';
	-- o_read_pkgs(12).rdata_parity <= (others => '0');
	-- o_read_pkgs(12).rdata <= (others => '0');
	-- o_read_pkgs(12).rid <= (others => '0');
	-- o_read_pkgs(12).rlast <= '0';
	-- o_read_pkgs(12).rresp <= (others => '0');
	-- o_read_pkgs(12).rvalid <= '0';
	-- o_write_pkgs(12).awready <= '0';
	-- o_write_pkgs(12).wready <= '0';
	-- o_write_pkgs(12).bid <= (others => '0');
	-- o_write_pkgs(12).bresp <= (others => '0');
	-- o_write_pkgs(12).bvalid <= '0';


	-- -- -------------------- AXI_13 --------------------
	-- hbm_13_araddr <= AXI_13_ARADDR;
	-- hbm_13_arburst <= AXI_13_ARBURST;
	-- hbm_13_arid <= AXI_13_ARID;
	-- hbm_13_arlen <= AXI_13_ARLEN;
	-- hbm_13_arsize <= AXI_13_ARSIZE;
	-- hbm_13_arvalid <= AXI_13_ARVALID;
	-- hbm_13_rready <= AXI_13_RREADY;
	-- hbm_13_awaddr <= AXI_13_AWADDR;
	-- hbm_13_awburst <= AXI_13_AWBURST;
	-- hbm_13_awid <= AXI_13_AWID;
	-- hbm_13_awlen <= AXI_13_AWLEN;
	-- hbm_13_awsize <= AXI_13_AWSIZE;
	-- hbm_13_awvalid <= AXI_13_AWVALID;
	-- hbm_13_wdata <= AXI_13_WDATA;
	-- hbm_13_wlast <= AXI_13_WLAST;
	-- hbm_13_wstrb <= AXI_13_WSTRB;
	-- hbm_13_wdata_parity <= AXI_13_WDATA_PARITY;
	-- hbm_13_wvalid <= AXI_13_WVALID;
	-- hbm_13_bready <= AXI_13_BREADY;

	-- AXI_13_ARREADY <= hbm_13_arready;
	-- AXI_13_RDATA_PARITY <= hbm_13_rdata_parity;
	-- AXI_13_RDATA <= hbm_13_rdata;
	-- AXI_13_RID <= hbm_13_rid;
	-- AXI_13_RLAST <= hbm_13_rlast;
	-- AXI_13_RRESP <= hbm_13_rresp;
	-- AXI_13_RVALID <= hbm_13_rvalid;
	-- AXI_13_AWREADY <= hbm_13_awready;
	-- AXI_13_WREADY <= hbm_13_wready;
	-- AXI_13_BID <= hbm_13_bid;
	-- AXI_13_BRESP <= hbm_13_bresp;
	-- AXI_13_BVALID <= hbm_13_bvalid;

	-- o_read_pkgs(13).arready <= '0';
	-- o_read_pkgs(13).rdata_parity <= (others => '0');
	-- o_read_pkgs(13).rdata <= (others => '0');
	-- o_read_pkgs(13).rid <= (others => '0');
	-- o_read_pkgs(13).rlast <= '0';
	-- o_read_pkgs(13).rresp <= (others => '0');
	-- o_read_pkgs(13).rvalid <= '0';
	-- o_write_pkgs(13).awready <= '0';
	-- o_write_pkgs(13).wready <= '0';
	-- o_write_pkgs(13).bid <= (others => '0');
	-- o_write_pkgs(13).bresp <= (others => '0');
	-- o_write_pkgs(13).bvalid <= '0';


	-- -- -------------------- AXI_14 --------------------
	-- hbm_14_araddr <= AXI_14_ARADDR;
	-- hbm_14_arburst <= AXI_14_ARBURST;
	-- hbm_14_arid <= AXI_14_ARID;
	-- hbm_14_arlen <= AXI_14_ARLEN;
	-- hbm_14_arsize <= AXI_14_ARSIZE;
	-- hbm_14_arvalid <= AXI_14_ARVALID;
	-- hbm_14_rready <= AXI_14_RREADY;
	-- hbm_14_awaddr <= AXI_14_AWADDR;
	-- hbm_14_awburst <= AXI_14_AWBURST;
	-- hbm_14_awid <= AXI_14_AWID;
	-- hbm_14_awlen <= AXI_14_AWLEN;
	-- hbm_14_awsize <= AXI_14_AWSIZE;
	-- hbm_14_awvalid <= AXI_14_AWVALID;
	-- hbm_14_wdata <= AXI_14_WDATA;
	-- hbm_14_wlast <= AXI_14_WLAST;
	-- hbm_14_wstrb <= AXI_14_WSTRB;
	-- hbm_14_wdata_parity <= AXI_14_WDATA_PARITY;
	-- hbm_14_wvalid <= AXI_14_WVALID;
	-- hbm_14_bready <= AXI_14_BREADY;

	-- AXI_14_ARREADY <= hbm_14_arready;
	-- AXI_14_RDATA_PARITY <= hbm_14_rdata_parity;
	-- AXI_14_RDATA <= hbm_14_rdata;
	-- AXI_14_RID <= hbm_14_rid;
	-- AXI_14_RLAST <= hbm_14_rlast;
	-- AXI_14_RRESP <= hbm_14_rresp;
	-- AXI_14_RVALID <= hbm_14_rvalid;
	-- AXI_14_AWREADY <= hbm_14_awready;
	-- AXI_14_WREADY <= hbm_14_wready;
	-- AXI_14_BID <= hbm_14_bid;
	-- AXI_14_BRESP <= hbm_14_bresp;
	-- AXI_14_BVALID <= hbm_14_bvalid;

	-- o_read_pkgs(14).arready <= '0';
	-- o_read_pkgs(14).rdata_parity <= (others => '0');
	-- o_read_pkgs(14).rdata <= (others => '0');
	-- o_read_pkgs(14).rid <= (others => '0');
	-- o_read_pkgs(14).rlast <= '0';
	-- o_read_pkgs(14).rresp <= (others => '0');
	-- o_read_pkgs(14).rvalid <= '0';
	-- o_write_pkgs(14).awready <= '0';
	-- o_write_pkgs(14).wready <= '0';
	-- o_write_pkgs(14).bid <= (others => '0');
	-- o_write_pkgs(14).bresp <= (others => '0');
	-- o_write_pkgs(14).bvalid <= '0';


	-- -- -------------------- AXI_15 --------------------
	-- hbm_15_araddr <= AXI_15_ARADDR;
	-- hbm_15_arburst <= AXI_15_ARBURST;
	-- hbm_15_arid <= AXI_15_ARID;
	-- hbm_15_arlen <= AXI_15_ARLEN;
	-- hbm_15_arsize <= AXI_15_ARSIZE;
	-- hbm_15_arvalid <= AXI_15_ARVALID;
	-- hbm_15_rready <= AXI_15_RREADY;
	-- hbm_15_awaddr <= AXI_15_AWADDR;
	-- hbm_15_awburst <= AXI_15_AWBURST;
	-- hbm_15_awid <= AXI_15_AWID;
	-- hbm_15_awlen <= AXI_15_AWLEN;
	-- hbm_15_awsize <= AXI_15_AWSIZE;
	-- hbm_15_awvalid <= AXI_15_AWVALID;
	-- hbm_15_wdata <= AXI_15_WDATA;
	-- hbm_15_wlast <= AXI_15_WLAST;
	-- hbm_15_wstrb <= AXI_15_WSTRB;
	-- hbm_15_wdata_parity <= AXI_15_WDATA_PARITY;
	-- hbm_15_wvalid <= AXI_15_WVALID;
	-- hbm_15_bready <= AXI_15_BREADY;

	-- AXI_15_ARREADY <= hbm_15_arready;
	-- AXI_15_RDATA_PARITY <= hbm_15_rdata_parity;
	-- AXI_15_RDATA <= hbm_15_rdata;
	-- AXI_15_RID <= hbm_15_rid;
	-- AXI_15_RLAST <= hbm_15_rlast;
	-- AXI_15_RRESP <= hbm_15_rresp;
	-- AXI_15_RVALID <= hbm_15_rvalid;
	-- AXI_15_AWREADY <= hbm_15_awready;
	-- AXI_15_WREADY <= hbm_15_wready;
	-- AXI_15_BID <= hbm_15_bid;
	-- AXI_15_BRESP <= hbm_15_bresp;
	-- AXI_15_BVALID <= hbm_15_bvalid;

	-- o_read_pkgs(15).arready <= '0';
	-- o_read_pkgs(15).rdata_parity <= (others => '0');
	-- o_read_pkgs(15).rdata <= (others => '0');
	-- o_read_pkgs(15).rid <= (others => '0');
	-- o_read_pkgs(15).rlast <= '0';
	-- o_read_pkgs(15).rresp <= (others => '0');
	-- o_read_pkgs(15).rvalid <= '0';
	-- o_write_pkgs(15).awready <= '0';
	-- o_write_pkgs(15).wready <= '0';
	-- o_write_pkgs(15).bid <= (others => '0');
	-- o_write_pkgs(15).bresp <= (others => '0');
	-- o_write_pkgs(15).bvalid <= '0';




end architecture;
