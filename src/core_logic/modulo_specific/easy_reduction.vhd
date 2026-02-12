----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.09.2024 14:32:11
-- Design Name: 
-- Module Name: easy_reduction
-- Project Name: TFHE Acceleration with FPGA
-- Target Devices: Virtex UltraScale+ HBM VCU128 FPGA
-- Tool Versions: Vivado 2024.1
-- Description: checks if value out of bound and substracts / adds a single time accordingly
--              Call this module after additions and substractions to keep the values in Zq.
--              Call ntt_mod or ntt_mult_mod_twiddle in case you did a multiplication before
--              and want the result in Zq.
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
     use work.datatypes_utils.all;
     use work.constants_utils.all;

entity easy_reduction is
     generic (
          modulus         : synthesiseable_uint;
          can_be_negative : boolean -- meaning: the number can be negative, so that you must add modulus instead of substracting it
     );
     port (
          i_clk     : in  std_ulogic;
          i_num     : in  synthesiseable_int_extended;
          o_mod_res : out synthesiseable_uint
     );
end entity;

architecture Behavioral of easy_reduction is

     signal result_buffer: synthesiseable_uint;

begin
     
     do_out_buf: if use_easy_red_out_buffer generate
          process (i_clk)
          begin
               if rising_edge(i_clk) then
                    o_mod_res <= result_buffer;
               end if;
          end process;
     end generate;
     no_out_buf: if not use_easy_red_out_buffer generate
          o_mod_res <= result_buffer;
     end generate;

     -- the actual addition / subtraction     

     add: if can_be_negative generate
          process (i_clk)
          begin
               if rising_edge(i_clk) then
                    if i_num(0) = '1' then
                         result_buffer <= to_synth_uint(i_num + to_synth_int_extended(modulus));
                    else
                         result_buffer <= to_synth_uint(i_num);
                    end if;
               end if;
          end process;
     end generate;

     sub: if not can_be_negative generate
          process (i_clk)
          begin
               if rising_edge(i_clk) then
                    if i_num > to_synth_int_extended(modulus) then
                         result_buffer <= to_synth_uint(i_num - to_synth_int_extended(modulus));
                    else
                         result_buffer <= to_synth_uint(i_num);
                    end if;
               end if;
          end process;
     end generate;

end architecture;
