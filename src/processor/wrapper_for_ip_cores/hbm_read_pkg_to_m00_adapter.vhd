-- Read-only adapter: convert one hbm_ps_in_read_pkg element into M00 AXI read
-- and convert M00 AXI read responses back to hbm_ps_out_read_pkg.
--
-- Usage: instantiate this adapter and connect its M_AXI_* read ports to
-- the `m00_axi_master_wrapper` M_AXI_* ports. Connect `i_hbm_read_in` to
-- the selected `hbm_ps_in_read_pkg` element (e.g., hbm_read_in_pkgs_stack_1(channel_idx))
-- and `o_hbm_read_out` to the corresponding `hbm_read_out_pkgs_stack_1(channel_idx)` element.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.ip_cores_constants.all; -- provides burstlen_pad_bits, id padding constants, widths
use work.processor_utils.all;    -- provides hbm_ps_* types

entity hbm_read_pkg_to_m00_adapter is
    port (
        -- clock / reset (use axi_clk / axi_reset_n)
        i_clk    : in  std_ulogic;
        i_reset_n: in  std_ulogic;
        -- HBM package side (single pseudo-channel)
        i_hbm_read_in  : in  hbm_ps_in_read_pkg;  -- araddr, arvalid, arid, rready, arlen
        o_hbm_read_out : out hbm_ps_out_read_pkg; -- rdata, rlast, rdata_parity, arready, rid, rresp, rvalid
        -- M00 AXI read channel (connect to m00 wrapper)
        M_AXI_ARID    : out std_logic_vector(axi_id_bit_width-1 downto 0);
        M_AXI_ARADDR  : out std_logic_vector(axi_addr_bits-1 downto 0);
        M_AXI_ARLEN   : out std_logic_vector(7 downto 0);
        M_AXI_ARSIZE  : out std_logic_vector(2 downto 0);
        M_AXI_ARBURST : out std_logic_vector(1 downto 0);
        M_AXI_ARLOCK  : out std_logic;
        M_AXI_ARCACHE : out std_logic_vector(3 downto 0);
        M_AXI_ARPROT  : out std_logic_vector(2 downto 0);
        M_AXI_ARQOS   : out std_logic_vector(3 downto 0);
        M_AXI_ARUSER  : out std_logic_vector(axi_region_bits-1 downto 0);
        M_AXI_ARVALID : out std_logic;
        M_AXI_ARREADY : in  std_logic;

        M_AXI_RID     : in  std_logic_vector(axi_id_bit_width-1 downto 0);
        M_AXI_RDATA   : in  std_logic_vector(axi_pkg_bit_size-1 downto 0);
        M_AXI_RRESP   : in  std_logic_vector(axi_resp_bits-1 downto 0);
        M_AXI_RLAST   : in  std_logic;
        M_AXI_RUSER   : in  std_logic_vector(axi_region_bits-1 downto 0);
        M_AXI_RVALID  : in  std_logic;
        M_AXI_RREADY  : out std_logic
    );
end entity;

architecture rtl of hbm_read_pkg_to_m00_adapter is
    signal ar_pending : std_ulogic := '0';
    -- internal driving signal for ARVALID (avoid reading an 'out' port inside process)
    signal M_AXI_ARVALID_sig : std_logic := '0';
begin
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset_n = '0' then
                M_AXI_ARVALID_sig <= '0';
                M_AXI_ARADDR  <= (others => '0');
                M_AXI_ARID    <= (others => '0');
                M_AXI_ARLEN   <= (others => '0');
                M_AXI_RREADY  <= '0';
                ar_pending    <= '0';
                o_hbm_read_out.rvalid <= '0';
                o_hbm_read_out.arready <= '0';
                o_hbm_read_out.rdata  <= (others => '0');
                o_hbm_read_out.rdata_parity <= (others => '0');
                o_hbm_read_out.rlast  <= '0';
                o_hbm_read_out.rid    <= (others => '0');
                o_hbm_read_out.rresp  <= (others => '0');
            else
                -- Drive AR channel when hbm pkg requests a read
                if i_hbm_read_in.arvalid = '1' and ar_pending = '0' then
                    -- present AR to M00 master
                    M_AXI_ARADDR  <= std_logic_vector(resize(i_hbm_read_in.araddr, M_AXI_ARADDR'length));
                    -- pad arlen to master width (8 bits)
                    M_AXI_ARLEN   <= burstlen_pad_bits & i_hbm_read_in.arlen;
                    -- id width should match; if not, zero-extend/truncate
                    if i_hbm_read_in.arid'length < M_AXI_ARID'length then
                        M_AXI_ARID <= id_pad_bits & i_hbm_read_in.arid;
                    elsif i_hbm_read_in.arid'length > M_AXI_ARID'length then
                        M_AXI_ARID <= i_hbm_read_in.arid(i_hbm_read_in.arid'length-1 downto i_hbm_read_in.arid'length - M_AXI_ARID'length);
                    else
                        M_AXI_ARID <= i_hbm_read_in.arid;
                    end if;
                    -- fixed protocol fields (match ip_cores_constants defaults)
                    M_AXI_ARSIZE  <= std_logic_vector(hbm_burstsize);
                    M_AXI_ARBURST <= std_logic_vector(hbm_burstmode);
                    M_AXI_ARLOCK  <= '0';
                    M_AXI_ARCACHE <= (others => '0');
                    M_AXI_ARPROT  <= (others => '0');
                    M_AXI_ARQOS   <= (others => '0');
                    M_AXI_ARUSER  <= (others => '0');
                    M_AXI_ARVALID_sig <= '1';
                    ar_pending    <= '1';
                    -- indicate to the HBM side whether AR was accepted by the interconnect
                    if M_AXI_ARREADY = '1' then
                        o_hbm_read_out.arready <= '1';
                    else
                        o_hbm_read_out.arready <= '0';
                    end if;
                    -- drive RREADY according to requester
                    if i_hbm_read_in.rready = '1' then
                        M_AXI_RREADY <= '1';
                    else
                        M_AXI_RREADY <= '0';
                    end if;
                else
                    -- once ARVALID is asserted, wait for ARREADY handshake
                    if M_AXI_ARVALID_sig = '1' then
                        if M_AXI_ARREADY = '1' then
                            M_AXI_ARVALID_sig <= '0';
                            -- keep RREADY as requested
                            if i_hbm_read_in.rready = '1' then
                                M_AXI_RREADY <= '1';
                            else
                                M_AXI_RREADY <= '0';
                            end if;
                        end if;
                    end if;

                    -- Handle incoming read data
                    if M_AXI_RVALID = '1' then
                        -- populate output package
                        o_hbm_read_out.rdata <= M_AXI_RDATA;
                        -- parity not available from generic master; set zero by default
                        o_hbm_read_out.rdata_parity <= (others => '0');
                        o_hbm_read_out.rlast <= M_AXI_RLAST;
                        o_hbm_read_out.rid   <= M_AXI_RID;
                        o_hbm_read_out.rresp <= M_AXI_RRESP;
                        o_hbm_read_out.rvalid <= '1';
                        -- De-assert pending when last beat received
                        if M_AXI_RLAST = '1' then
                            ar_pending <= '0';
                            M_AXI_RREADY <= '0';
                        end if;
                    else
                        o_hbm_read_out.rvalid <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    -- drive output port from internal signal to avoid reading an 'out' port
    M_AXI_ARVALID <= M_AXI_ARVALID_sig;

end architecture;
