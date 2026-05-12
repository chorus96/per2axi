# Vivado XGUI metadata for the per2axi custom IP.

proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"

  set param_page [ipgui::add_page $IPINST -name "Parameters"]
  ipgui::add_param $IPINST -name "NB_CORES"       -parent ${param_page}
  ipgui::add_param $IPINST -name "PER_ADDR_WIDTH" -parent ${param_page}
  ipgui::add_param $IPINST -name "PER_ID_WIDTH"   -parent ${param_page}
  ipgui::add_param $IPINST -name "AXI_ADDR_WIDTH" -parent ${param_page}
  ipgui::add_param $IPINST -name "AXI_DATA_WIDTH" -parent ${param_page}
  ipgui::add_param $IPINST -name "AXI_USER_WIDTH" -parent ${param_page}
  ipgui::add_param $IPINST -name "AXI_ID_WIDTH"   -parent ${param_page}
  ipgui::add_param $IPINST -name "AXI_STRB_WIDTH" -parent ${param_page}
}

proc update_PARAM_VALUE.NB_CORES { PARAM_VALUE.NB_CORES } {}
proc update_PARAM_VALUE.PER_ADDR_WIDTH { PARAM_VALUE.PER_ADDR_WIDTH } {}
proc update_PARAM_VALUE.PER_ID_WIDTH { PARAM_VALUE.PER_ID_WIDTH } {}
proc update_PARAM_VALUE.AXI_ADDR_WIDTH { PARAM_VALUE.AXI_ADDR_WIDTH } {}
proc update_PARAM_VALUE.AXI_DATA_WIDTH { PARAM_VALUE.AXI_DATA_WIDTH } {}
proc update_PARAM_VALUE.AXI_USER_WIDTH { PARAM_VALUE.AXI_USER_WIDTH } {}
proc update_PARAM_VALUE.AXI_ID_WIDTH { PARAM_VALUE.AXI_ID_WIDTH } {}
proc update_PARAM_VALUE.AXI_STRB_WIDTH { PARAM_VALUE.AXI_STRB_WIDTH PARAM_VALUE.AXI_DATA_WIDTH } {
  set data_width [get_property value ${PARAM_VALUE.AXI_DATA_WIDTH}]
  if {[string is integer -strict $data_width] && $data_width > 0} {
    set_property value [expr {$data_width / 8}] ${PARAM_VALUE.AXI_STRB_WIDTH}
  }
}

proc validate_PARAM_VALUE.NB_CORES { PARAM_VALUE.NB_CORES } { return true }
proc validate_PARAM_VALUE.PER_ADDR_WIDTH { PARAM_VALUE.PER_ADDR_WIDTH } { return true }
proc validate_PARAM_VALUE.PER_ID_WIDTH { PARAM_VALUE.PER_ID_WIDTH } { return true }
proc validate_PARAM_VALUE.AXI_ADDR_WIDTH { PARAM_VALUE.AXI_ADDR_WIDTH } { return true }
proc validate_PARAM_VALUE.AXI_DATA_WIDTH { PARAM_VALUE.AXI_DATA_WIDTH } { return true }
proc validate_PARAM_VALUE.AXI_USER_WIDTH { PARAM_VALUE.AXI_USER_WIDTH } { return true }
proc validate_PARAM_VALUE.AXI_ID_WIDTH { PARAM_VALUE.AXI_ID_WIDTH } { return true }
proc validate_PARAM_VALUE.AXI_STRB_WIDTH { PARAM_VALUE.AXI_STRB_WIDTH } { return true }

proc update_MODELPARAM_VALUE.NB_CORES { MODELPARAM_VALUE.NB_CORES PARAM_VALUE.NB_CORES } {
  set_property value [get_property value ${PARAM_VALUE.NB_CORES}] ${MODELPARAM_VALUE.NB_CORES}
}
proc update_MODELPARAM_VALUE.PER_ADDR_WIDTH { MODELPARAM_VALUE.PER_ADDR_WIDTH PARAM_VALUE.PER_ADDR_WIDTH } {
  set_property value [get_property value ${PARAM_VALUE.PER_ADDR_WIDTH}] ${MODELPARAM_VALUE.PER_ADDR_WIDTH}
}
proc update_MODELPARAM_VALUE.PER_ID_WIDTH { MODELPARAM_VALUE.PER_ID_WIDTH PARAM_VALUE.PER_ID_WIDTH } {
  set_property value [get_property value ${PARAM_VALUE.PER_ID_WIDTH}] ${MODELPARAM_VALUE.PER_ID_WIDTH}
}
proc update_MODELPARAM_VALUE.AXI_ADDR_WIDTH { MODELPARAM_VALUE.AXI_ADDR_WIDTH PARAM_VALUE.AXI_ADDR_WIDTH } {
  set_property value [get_property value ${PARAM_VALUE.AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.AXI_ADDR_WIDTH}
}
proc update_MODELPARAM_VALUE.AXI_DATA_WIDTH { MODELPARAM_VALUE.AXI_DATA_WIDTH PARAM_VALUE.AXI_DATA_WIDTH } {
  set_property value [get_property value ${PARAM_VALUE.AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.AXI_DATA_WIDTH}
}
proc update_MODELPARAM_VALUE.AXI_USER_WIDTH { MODELPARAM_VALUE.AXI_USER_WIDTH PARAM_VALUE.AXI_USER_WIDTH } {
  set_property value [get_property value ${PARAM_VALUE.AXI_USER_WIDTH}] ${MODELPARAM_VALUE.AXI_USER_WIDTH}
}
proc update_MODELPARAM_VALUE.AXI_ID_WIDTH { MODELPARAM_VALUE.AXI_ID_WIDTH PARAM_VALUE.AXI_ID_WIDTH } {
  set_property value [get_property value ${PARAM_VALUE.AXI_ID_WIDTH}] ${MODELPARAM_VALUE.AXI_ID_WIDTH}
}
proc update_MODELPARAM_VALUE.AXI_STRB_WIDTH { MODELPARAM_VALUE.AXI_STRB_WIDTH PARAM_VALUE.AXI_STRB_WIDTH } {
  set_property value [get_property value ${PARAM_VALUE.AXI_STRB_WIDTH}] ${MODELPARAM_VALUE.AXI_STRB_WIDTH}
}
