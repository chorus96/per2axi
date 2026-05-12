# Repackage per2axi as an AMD Vivado custom IP without copying RTL sources.
set script_dir [file normalize [file dirname [info script]]]
set repo_root  [file normalize [file join $script_dir ../..]]
set ip_root    $script_dir

ipx::package_project \
  -root_dir $ip_root \
  -vendor chorus96 \
  -library user \
  -taxonomy /UserIP \
  -import_files false \
  -set_current true \
  -force

set core [ipx::current_core]
set_property name per2axi $core
set_property display_name {per2axi Peripheral to AXI Bridge} $core
set_property description {Peripheral interconnect slave to AXI4 master bridge} $core
set_property version 1.0 $core
set_property supported_families {zynquplus Production zynq Production virtexuplus Production kintexuplus Production artixuplus Production} $core
set_property top per2axi $core

foreach src_file { \
  src/per2axi_busy_unit.sv \
  src/per2axi_req_channel.sv \
  src/per2axi_res_channel.sv \
  src/per2axi.sv \
} {
  set abs_file [file normalize [file join $repo_root $src_file]]
  set synth_file_obj [ipx::add_file $abs_file [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects $core]]
  set_property type systemVerilogSource $synth_file_obj

  set sim_file_obj [ipx::add_file $abs_file [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects $core]]
  set_property type systemVerilogSource $sim_file_obj
}

ipx::update_checksums $core
ipx::save_core $core
