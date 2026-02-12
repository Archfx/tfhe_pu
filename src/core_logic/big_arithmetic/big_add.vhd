----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.09.2024 14:32:11
-- Design Name: 
-- Module Name: big_add
-- Project Name: TFHE Acceleration with FPGA
-- Target Devices: Virtex UltraScale+ HBM VCU128 FPGA
-- Tool Versions: Vivado 2024.1
-- Description: outsourcing of bigger-than-DSP-size arithmetic operation
--             with additional registers, so that retiming can happen
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
     use work.datatypes_utils.all;

entity big_add is
     generic (
          substraction : boolean := false
     );
     port (
          i_clk  : in  std_ulogic;
          i_num0 : in  synthesiseable_int;
          i_num1 : in  synthesiseable_int;
          o_res  : out synthesiseable_int_extended
     );
end entity;

architecture Behavioral of big_add is

begin

     add: if not substraction generate
          process (i_clk)
          begin
               if rising_edge(i_clk) then
                    o_res <= to_synth_int_extended(i_num0) + to_synth_int_extended(i_num1);
               end if;
          end process;
     end generate;

     sub: if substraction generate
          process (i_clk)
          begin
               if rising_edge(i_clk) then
                    o_res <= to_synth_int_extended(i_num0) - to_synth_int_extended(i_num1);
               end if;
          end process;
     end generate;

end architecture;
