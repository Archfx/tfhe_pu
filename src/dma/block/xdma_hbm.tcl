
################################################################
# This is a generated script based on design: xdma_hbm
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source xdma_hbm_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# tfhe_w

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvu37p-fsvh2892-2L-e
   set_property BOARD_PART xilinx.com:vcu128:part0:1.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name xdma_hbm

# This script was generated for a remote BD. To create a non-remote design,
# change the variable <run_remote_bd_flow> to <0>.

set run_remote_bd_flow 1
if { $run_remote_bd_flow == 1 } {
  # Set the reference directory for source file relative paths (by default 
  # the value is script directory path)
  set origin_dir ./xdma_tfhe/xdma_hbm_block

  # Use origin directory path location variable, if specified in the tcl shell
  if { [info exists ::origin_dir_loc] } {
     set origin_dir $::origin_dir_loc
  }

  set str_bd_folder [file normalize ${origin_dir}]
  set str_bd_filepath ${str_bd_folder}/${design_name}/${design_name}.bd

  # Check if remote design exists on disk
  if { [file exists $str_bd_filepath ] == 1 } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2030 -severity "ERROR" "The remote BD file path <$str_bd_filepath> already exists!"}
     common::send_gid_msg -ssname BD::TCL -id 2031 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0>."
     common::send_gid_msg -ssname BD::TCL -id 2032 -severity "INFO" "Also make sure there is no design <$design_name> existing in your current project."

     return 1
  }

  # Check if design exists in memory
  set list_existing_designs [get_bd_designs -quiet $design_name]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2033 -severity "ERROR" "The design <$design_name> already exists in this project! Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2034 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Check if design exists on disk within project
  set list_existing_designs [get_files -quiet */${design_name}.bd]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2035 -severity "ERROR" "The design <$design_name> already exists in this project at location:
    $list_existing_designs"}
     catch {common::send_gid_msg -ssname BD::TCL -id 2036 -severity "ERROR" "Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2037 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Now can create the remote BD
  # NOTE - usage of <-dir> will create <$str_bd_folder/$design_name/$design_name.bd>
  create_bd_design -dir $str_bd_folder $design_name
} else {

  # Create regular design
  if { [catch {create_bd_design $design_name} errmsg] } {
     common::send_gid_msg -ssname BD::TCL -id 2038 -severity "INFO" "Please set a different value to variable <design_name>."

     return 1
  }
}

current_bd_design $design_name

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:xdma:4.2\
xilinx.com:ip:hbm:1.0\
xilinx.com:ip:util_ds_buf:2.2\
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:proc_sys_reset:5.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
tfhe_w\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set pci_express_x8 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_express_x8 ]

  set pcie_refclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $pcie_refclk

  set default_100mhz_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_100mhz_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
   ] $default_100mhz_clk


  # Create ports
  set pcie_perstn [ create_bd_port -dir I -type rst pcie_perstn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $pcie_perstn
  set leds [ create_bd_port -dir O -from 7 -to 0 leds ]

  # Create instance: xdma_0, and set properties
  set xdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.2 xdma_0 ]
  set_property -dict [list \
    CONFIG.PCIE_BOARD_INTERFACE {pci_express_x8} \
    CONFIG.SYS_RST_N_BOARD_INTERFACE {pcie_perstn} \
    CONFIG.axi_data_width {256_bit} \
    CONFIG.axilite_master_en {true} \
    CONFIG.axisten_freq {250} \
    CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
    CONFIG.xdma_axi_intf_mm {AXI_Memory_Mapped} \
    CONFIG.xdma_rnum_chnl {4} \
    CONFIG.xdma_wnum_chnl {4} \
  ] $xdma_0


  # Create instance: hbm_0, and set properties
  set hbm_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:hbm:1.0 hbm_0 ]
  set_property -dict [list \
    CONFIG.USER_APB_EN {false} \
    CONFIG.USER_HBM_TCK_0 {500} \
    CONFIG.USER_MC0_EN_DATA_MASK {false} \
    CONFIG.USER_MC0_TRAFFIC_OPTION {Linear} \
    CONFIG.USER_MC_ENABLE_01 {TRUE} \
    CONFIG.USER_MC_ENABLE_02 {TRUE} \
    CONFIG.USER_MC_ENABLE_03 {TRUE} \
    CONFIG.USER_MC_ENABLE_04 {TRUE} \
    CONFIG.USER_MC_ENABLE_05 {TRUE} \
    CONFIG.USER_MC_ENABLE_06 {TRUE} \
    CONFIG.USER_MC_ENABLE_07 {TRUE} \
    CONFIG.USER_SAXI_00 {true} \
    CONFIG.USER_SAXI_01 {true} \
    CONFIG.USER_SINGLE_STACK_SELECTION {RIGHT} \
    CONFIG.USER_SWITCH_ENABLE_00 {FALSE} \
  ] $hbm_0


  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf ]
  set_property -dict [list \
    CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {pcie_refclk} \
    CONFIG.USE_BOARD_FLOW {true} \
  ] $util_ds_buf


  # Create instance: axi_mem_intercon, and set properties
  set axi_mem_intercon [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_mem_intercon ]
  set_property -dict [list \
    CONFIG.NUM_MI {16} \
    CONFIG.NUM_SI {3} \
  ] $axi_mem_intercon


  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.AUTO_PRIMITIVE {PLL} \
    CONFIG.CLKIN2_JITTER_PS {149.99} \
    CONFIG.CLKOUT1_DRIVES {BUFG} \
    CONFIG.CLKOUT1_JITTER {144.719} \
    CONFIG.CLKOUT1_PHASE_ERROR {114.212} \
    CONFIG.CLKOUT2_DRIVES {Buffer} \
    CONFIG.CLKOUT2_JITTER {144.719} \
    CONFIG.CLKOUT2_PHASE_ERROR {114.212} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_DRIVES {Buffer} \
    CONFIG.CLKOUT4_DRIVES {Buffer} \
    CONFIG.CLKOUT5_DRIVES {Buffer} \
    CONFIG.CLKOUT6_DRIVES {Buffer} \
    CONFIG.CLKOUT7_DRIVES {Buffer} \
    CONFIG.CLK_IN1_BOARD_INTERFACE {default_100mhz_clk} \
    CONFIG.CLK_IN2_BOARD_INTERFACE {Custom} \
    CONFIG.CLK_OUT2_PORT {tfhe_clk} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.MMCM_BANDWIDTH {OPTIMIZED} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {8} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {8} \
    CONFIG.MMCM_CLKOUT1_DIVIDE {8} \
    CONFIG.MMCM_COMPENSATION {AUTO} \
    CONFIG.NUM_OUT_CLKS {2} \
    CONFIG.OPTIMIZE_CLOCKING_STRUCTURE_EN {true} \
    CONFIG.PRIMITIVE {Auto} \
    CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} \
    CONFIG.RESET_BOARD_INTERFACE {Custom} \
    CONFIG.SECONDARY_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.USE_BOARD_FLOW {true} \
    CONFIG.USE_INCLK_SWITCHOVER {false} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {false} \
  ] $clk_wiz_0


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: tfhe_w_0, and set properties
  set block_name tfhe_w
  set block_cell_name tfhe_w_0
  if { [catch {set tfhe_w_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $tfhe_w_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net axi_mem_intercon_M00_AXI [get_bd_intf_pins axi_mem_intercon/M00_AXI] [get_bd_intf_pins hbm_0/SAXI_00_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M01_AXI [get_bd_intf_pins axi_mem_intercon/M01_AXI] [get_bd_intf_pins hbm_0/SAXI_01_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M02_AXI [get_bd_intf_pins axi_mem_intercon/M02_AXI] [get_bd_intf_pins hbm_0/SAXI_15_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M03_AXI [get_bd_intf_pins axi_mem_intercon/M03_AXI] [get_bd_intf_pins hbm_0/SAXI_02_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M04_AXI [get_bd_intf_pins axi_mem_intercon/M04_AXI] [get_bd_intf_pins hbm_0/SAXI_03_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M05_AXI [get_bd_intf_pins axi_mem_intercon/M05_AXI] [get_bd_intf_pins hbm_0/SAXI_04_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M06_AXI [get_bd_intf_pins axi_mem_intercon/M06_AXI] [get_bd_intf_pins hbm_0/SAXI_05_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M07_AXI [get_bd_intf_pins axi_mem_intercon/M07_AXI] [get_bd_intf_pins hbm_0/SAXI_06_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M08_AXI [get_bd_intf_pins axi_mem_intercon/M08_AXI] [get_bd_intf_pins hbm_0/SAXI_07_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M09_AXI [get_bd_intf_pins axi_mem_intercon/M09_AXI] [get_bd_intf_pins hbm_0/SAXI_08_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M10_AXI [get_bd_intf_pins axi_mem_intercon/M10_AXI] [get_bd_intf_pins hbm_0/SAXI_09_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M11_AXI [get_bd_intf_pins axi_mem_intercon/M11_AXI] [get_bd_intf_pins hbm_0/SAXI_10_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M12_AXI [get_bd_intf_pins axi_mem_intercon/M12_AXI] [get_bd_intf_pins hbm_0/SAXI_11_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M13_AXI [get_bd_intf_pins axi_mem_intercon/M13_AXI] [get_bd_intf_pins hbm_0/SAXI_12_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M14_AXI [get_bd_intf_pins axi_mem_intercon/M14_AXI] [get_bd_intf_pins hbm_0/SAXI_13_RT]
  connect_bd_intf_net -intf_net axi_mem_intercon_M15_AXI [get_bd_intf_pins axi_mem_intercon/M15_AXI] [get_bd_intf_pins hbm_0/SAXI_14_RT]
  connect_bd_intf_net -intf_net default_100mhz_clk_1 [get_bd_intf_ports default_100mhz_clk] [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]
  connect_bd_intf_net -intf_net pcie_refclk_1 [get_bd_intf_ports pcie_refclk] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  connect_bd_intf_net -intf_net tfhe_w_0_m00_axi [get_bd_intf_pins tfhe_w_0/m00_axi] [get_bd_intf_pins axi_mem_intercon/S01_AXI]
  connect_bd_intf_net -intf_net tfhe_w_0_m01_axi [get_bd_intf_pins tfhe_w_0/m01_axi] [get_bd_intf_pins axi_mem_intercon/S02_AXI]
  connect_bd_intf_net -intf_net xdma_0_M_AXI [get_bd_intf_pins xdma_0/M_AXI] [get_bd_intf_pins axi_mem_intercon/S00_AXI]
  connect_bd_intf_net -intf_net xdma_0_M_AXI_LITE [get_bd_intf_pins xdma_0/M_AXI_LITE] [get_bd_intf_pins tfhe_w_0/s00_axi]
  connect_bd_intf_net -intf_net xdma_0_pcie_mgt [get_bd_intf_ports pci_express_x8] [get_bd_intf_pins xdma_0/pcie_mgt]

  # Create port connections
  connect_bd_net -net clk_wiz_clk_out1  [get_bd_pins clk_wiz_0/clk_out1] \
  [get_bd_pins hbm_0/HBM_REF_CLK_0] \
  [get_bd_pins hbm_0/APB_0_PCLK] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
  [get_bd_pins tfhe_w_0/tfhe_clk]
  connect_bd_net -net pcie_perstn_1  [get_bd_ports pcie_perstn] \
  [get_bd_pins xdma_0/sys_rst_n]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins hbm_0/APB_0_PRESET_N]
  connect_bd_net -net tfhe_w_0_user_led  [get_bd_pins tfhe_w_0/user_led] \
  [get_bd_ports leds]
  connect_bd_net -net util_ds_buf_IBUF_DS_ODIV2  [get_bd_pins util_ds_buf/IBUF_DS_ODIV2] \
  [get_bd_pins xdma_0/sys_clk]
  connect_bd_net -net util_ds_buf_IBUF_OUT  [get_bd_pins util_ds_buf/IBUF_OUT] \
  [get_bd_pins xdma_0/sys_clk_gt]
  connect_bd_net -net xdma_0_axi_aclk  [get_bd_pins xdma_0/axi_aclk] \
  [get_bd_pins axi_mem_intercon/S00_ACLK] \
  [get_bd_pins hbm_0/AXI_00_ACLK] \
  [get_bd_pins axi_mem_intercon/M00_ACLK] \
  [get_bd_pins axi_mem_intercon/ACLK] \
  [get_bd_pins hbm_0/AXI_01_ACLK] \
  [get_bd_pins axi_mem_intercon/M01_ACLK] \
  [get_bd_pins axi_mem_intercon/M02_ACLK] \
  [get_bd_pins axi_mem_intercon/M03_ACLK] \
  [get_bd_pins axi_mem_intercon/M04_ACLK] \
  [get_bd_pins axi_mem_intercon/M05_ACLK] \
  [get_bd_pins axi_mem_intercon/M06_ACLK] \
  [get_bd_pins axi_mem_intercon/M07_ACLK] \
  [get_bd_pins axi_mem_intercon/M08_ACLK] \
  [get_bd_pins axi_mem_intercon/M09_ACLK] \
  [get_bd_pins axi_mem_intercon/M10_ACLK] \
  [get_bd_pins axi_mem_intercon/M11_ACLK] \
  [get_bd_pins axi_mem_intercon/M12_ACLK] \
  [get_bd_pins axi_mem_intercon/M13_ACLK] \
  [get_bd_pins axi_mem_intercon/M14_ACLK] \
  [get_bd_pins axi_mem_intercon/M15_ACLK] \
  [get_bd_pins hbm_0/AXI_02_ACLK] \
  [get_bd_pins hbm_0/AXI_03_ACLK] \
  [get_bd_pins hbm_0/AXI_04_ACLK] \
  [get_bd_pins hbm_0/AXI_05_ACLK] \
  [get_bd_pins hbm_0/AXI_06_ACLK] \
  [get_bd_pins hbm_0/AXI_07_ACLK] \
  [get_bd_pins hbm_0/AXI_08_ACLK] \
  [get_bd_pins hbm_0/AXI_09_ACLK] \
  [get_bd_pins hbm_0/AXI_10_ACLK] \
  [get_bd_pins hbm_0/AXI_11_ACLK] \
  [get_bd_pins hbm_0/AXI_12_ACLK] \
  [get_bd_pins hbm_0/AXI_13_ACLK] \
  [get_bd_pins hbm_0/AXI_14_ACLK] \
  [get_bd_pins hbm_0/AXI_15_ACLK] \
  [get_bd_pins axi_mem_intercon/S01_ACLK] \
  [get_bd_pins axi_mem_intercon/S02_ACLK] \
  [get_bd_pins tfhe_w_0/m00_axi_aclk] \
  [get_bd_pins tfhe_w_0/m01_axi_aclk] \
  [get_bd_pins tfhe_w_0/s00_axi_aclk]
  connect_bd_net -net xdma_0_axi_aresetn  [get_bd_pins xdma_0/axi_aresetn] \
  [get_bd_pins axi_mem_intercon/S00_ARESETN] \
  [get_bd_pins hbm_0/AXI_00_ARESET_N] \
  [get_bd_pins axi_mem_intercon/M00_ARESETN] \
  [get_bd_pins axi_mem_intercon/ARESETN] \
  [get_bd_pins hbm_0/AXI_01_ARESET_N] \
  [get_bd_pins axi_mem_intercon/M01_ARESETN] \
  [get_bd_pins axi_mem_intercon/M02_ARESETN] \
  [get_bd_pins axi_mem_intercon/M03_ARESETN] \
  [get_bd_pins axi_mem_intercon/M04_ARESETN] \
  [get_bd_pins axi_mem_intercon/M05_ARESETN] \
  [get_bd_pins axi_mem_intercon/M06_ARESETN] \
  [get_bd_pins axi_mem_intercon/M07_ARESETN] \
  [get_bd_pins axi_mem_intercon/M08_ARESETN] \
  [get_bd_pins axi_mem_intercon/M09_ARESETN] \
  [get_bd_pins axi_mem_intercon/M10_ARESETN] \
  [get_bd_pins axi_mem_intercon/M11_ARESETN] \
  [get_bd_pins axi_mem_intercon/M12_ARESETN] \
  [get_bd_pins axi_mem_intercon/M13_ARESETN] \
  [get_bd_pins axi_mem_intercon/M14_ARESETN] \
  [get_bd_pins axi_mem_intercon/M15_ARESETN] \
  [get_bd_pins proc_sys_reset_0/ext_reset_in] \
  [get_bd_pins hbm_0/AXI_02_ARESET_N] \
  [get_bd_pins hbm_0/AXI_03_ARESET_N] \
  [get_bd_pins hbm_0/AXI_04_ARESET_N] \
  [get_bd_pins hbm_0/AXI_05_ARESET_N] \
  [get_bd_pins hbm_0/AXI_06_ARESET_N] \
  [get_bd_pins hbm_0/AXI_07_ARESET_N] \
  [get_bd_pins hbm_0/AXI_08_ARESET_N] \
  [get_bd_pins hbm_0/AXI_09_ARESET_N] \
  [get_bd_pins hbm_0/AXI_10_ARESET_N] \
  [get_bd_pins hbm_0/AXI_11_ARESET_N] \
  [get_bd_pins hbm_0/AXI_12_ARESET_N] \
  [get_bd_pins hbm_0/AXI_13_ARESET_N] \
  [get_bd_pins hbm_0/AXI_14_ARESET_N] \
  [get_bd_pins hbm_0/AXI_15_ARESET_N] \
  [get_bd_pins axi_mem_intercon/S01_ARESETN] \
  [get_bd_pins axi_mem_intercon/S02_ARESETN] \
  [get_bd_pins tfhe_w_0/m00_axi_aresetn] \
  [get_bd_pins tfhe_w_0/m01_axi_aresetn] \
  [get_bd_pins tfhe_w_0/s00_axi_aresetn]

  # Create address segments
  assign_bd_address -offset 0x000100000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_00_RT/HBM_MEM00] -force
  assign_bd_address -offset 0x000110000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_01_RT/HBM_MEM01] -force
  assign_bd_address -offset 0x000120000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_02_RT/HBM_MEM02] -force
  assign_bd_address -offset 0x000130000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_03_RT/HBM_MEM03] -force
  assign_bd_address -offset 0x000140000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_04_RT/HBM_MEM04] -force
  assign_bd_address -offset 0x000150000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_05_RT/HBM_MEM05] -force
  assign_bd_address -offset 0x000160000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_06_RT/HBM_MEM06] -force
  assign_bd_address -offset 0x000170000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_07_RT/HBM_MEM07] -force
  assign_bd_address -offset 0x000180000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_08_RT/HBM_MEM08] -force
  assign_bd_address -offset 0x000190000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_09_RT/HBM_MEM09] -force
  assign_bd_address -offset 0x0001A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_10_RT/HBM_MEM10] -force
  assign_bd_address -offset 0x0001B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_11_RT/HBM_MEM11] -force
  assign_bd_address -offset 0x0001C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_12_RT/HBM_MEM12] -force
  assign_bd_address -offset 0x0001D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_13_RT/HBM_MEM13] -force
  assign_bd_address -offset 0x0001E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_14_RT/HBM_MEM14] -force
  assign_bd_address -offset 0x0001F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI] [get_bd_addr_segs hbm_0/SAXI_15_RT/HBM_MEM15] -force
  assign_bd_address -offset 0x00000000 -range 0x00001000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs tfhe_w_0/s00_axi/reg0] -force
  assign_bd_address -offset 0x000100000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_00_RT/HBM_MEM00] -force
  assign_bd_address -offset 0x000110000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_01_RT/HBM_MEM01] -force
  assign_bd_address -offset 0x000120000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_02_RT/HBM_MEM02] -force
  assign_bd_address -offset 0x000130000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_03_RT/HBM_MEM03] -force
  assign_bd_address -offset 0x000140000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_04_RT/HBM_MEM04] -force
  assign_bd_address -offset 0x000150000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_05_RT/HBM_MEM05] -force
  assign_bd_address -offset 0x000160000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_06_RT/HBM_MEM06] -force
  assign_bd_address -offset 0x000170000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_07_RT/HBM_MEM07] -force
  assign_bd_address -offset 0x000180000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_08_RT/HBM_MEM08] -force
  assign_bd_address -offset 0x000190000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_09_RT/HBM_MEM09] -force
  assign_bd_address -offset 0x0001A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_10_RT/HBM_MEM10] -force
  assign_bd_address -offset 0x0001B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_11_RT/HBM_MEM11] -force
  assign_bd_address -offset 0x0001C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_12_RT/HBM_MEM12] -force
  assign_bd_address -offset 0x0001D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_13_RT/HBM_MEM13] -force
  assign_bd_address -offset 0x0001E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_14_RT/HBM_MEM14] -force
  assign_bd_address -offset 0x0001F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m00_axi] [get_bd_addr_segs hbm_0/SAXI_15_RT/HBM_MEM15] -force
  assign_bd_address -offset 0x000100000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_00_RT/HBM_MEM00] -force
  assign_bd_address -offset 0x000110000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_01_RT/HBM_MEM01] -force
  assign_bd_address -offset 0x000120000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_02_RT/HBM_MEM02] -force
  assign_bd_address -offset 0x000130000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_03_RT/HBM_MEM03] -force
  assign_bd_address -offset 0x000140000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_04_RT/HBM_MEM04] -force
  assign_bd_address -offset 0x000150000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_05_RT/HBM_MEM05] -force
  assign_bd_address -offset 0x000160000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_06_RT/HBM_MEM06] -force
  assign_bd_address -offset 0x000170000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_07_RT/HBM_MEM07] -force
  assign_bd_address -offset 0x000180000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_08_RT/HBM_MEM08] -force
  assign_bd_address -offset 0x000190000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_09_RT/HBM_MEM09] -force
  assign_bd_address -offset 0x0001A0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_10_RT/HBM_MEM10] -force
  assign_bd_address -offset 0x0001B0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_11_RT/HBM_MEM11] -force
  assign_bd_address -offset 0x0001C0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_12_RT/HBM_MEM12] -force
  assign_bd_address -offset 0x0001D0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_13_RT/HBM_MEM13] -force
  assign_bd_address -offset 0x0001E0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_14_RT/HBM_MEM14] -force
  assign_bd_address -offset 0x0001F0000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces tfhe_w_0/m01_axi] [get_bd_addr_segs hbm_0/SAXI_15_RT/HBM_MEM15] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_gid_msg -ssname BD::TCL -id 2053 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

