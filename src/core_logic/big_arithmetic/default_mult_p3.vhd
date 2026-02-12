----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.09.2024 14:32:11
-- Design Name: 
-- Module Name: default_mult
-- Project Name: TFHE Acceleration with FPGA
-- Target Devices: Virtex UltraScale+ HBM VCU128 FPGA
-- Tool Versions: Vivado 2024.1
-- Description: 
-- Dependencies: see imports
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
     use IEEE.STD_LOGIC_1164.all;
     use IEEE.numeric_std.all;
library work;
     use work.constants_utils.all;

entity default_mult_p3 is
     generic (
          base_len            : integer;
          dsp_retiming_length : integer
     );
     port (
          i_clk  : in  std_ulogic;
          i_num0 : in  unsigned(0 to base_len - 1);
          i_num1_b0 : in  unsigned(0 to base_len - 2);
          i_num1_b1 : in  unsigned(0 to base_len- 2);
          o_res  : out unsigned(0 to 2 * base_len - 1)
     );
end entity;

architecture Behavioral of default_mult_p3 is

     -- wait registers for the multiplication result which are pushed back into the DSPs
     type wait_registers_mult_result is array (natural range <>) of unsigned(0 to o_res'length - 1);
     signal res_wait_regs : wait_registers_mult_result(0 to dsp_retiming_length-1 - 1); -- -1 because of input register
     signal num0_buf: unsigned(0 to i_num0'length-1);
     signal num1_b0_buf: unsigned(0 to i_num1_b0'length-1);
     signal num1_b1_buf: unsigned(0 to i_num1_b1'length-1);

begin

     o_res <= res_wait_regs(res_wait_regs'length - 1);

    num1_b1_buf <= i_num1_b1;
    num0_buf <= i_num0;
     process (i_clk)
     begin
          if rising_edge(i_clk) then
               num1_b0_buf <= i_num1_b0;
               res_wait_regs(0) <= num0_buf * (('0' & num1_b1_buf) + num1_b0_buf);
               res_wait_regs(1 to res_wait_regs'length - 1) <= res_wait_regs(0 to res_wait_regs'length - 2);
          end if;
     end process;

end architecture;
