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

proc validate_PARAM_VALUE.NB_CORES { PARAM_VALUE.NB_CORES } {
  set v [get_property value ${PARAM_VALUE.NB_CORES}]
  if {![string is integer -strict $v] || $v < 1} {
    set_property errmsg "NB_CORES must be an integer >= 1" ${PARAM_VALUE.NB_CORES}
    return false
  }
  return true
}
proc validate_PARAM_VALUE.PER_ADDR_WIDTH { PARAM_VALUE.PER_ADDR_WIDTH } {
  set v [get_property value ${PARAM_VALUE.PER_ADDR_WIDTH}]
  if {![string is integer -strict $v] || $v < 3} {
    set_property errmsg "PER_ADDR_WIDTH must be an integer >= 3 (addr\[2\] selects upper/lower 32 bits)" ${PARAM_VALUE.PER_ADDR_WIDTH}
    return false
  }
  return true
}
proc validate_PARAM_VALUE.PER_ID_WIDTH { PARAM_VALUE.PER_ID_WIDTH } {
  set v [get_property value ${PARAM_VALUE.PER_ID_WIDTH}]
  if {![string is integer -strict $v] || $v < 1} {
    set_property errmsg "PER_ID_WIDTH must be an integer >= 1" ${PARAM_VALUE.PER_ID_WIDTH}
    return false
  }
  return true
}
proc validate_PARAM_VALUE.AXI_ADDR_WIDTH { PARAM_VALUE.AXI_ADDR_WIDTH } {
  set v [get_property value ${PARAM_VALUE.AXI_ADDR_WIDTH}]
  if {![string is integer -strict $v] || $v < 3} {
    set_property errmsg "AXI_ADDR_WIDTH must be an integer >= 3" ${PARAM_VALUE.AXI_ADDR_WIDTH}
    return false
  }
  return true
}
proc validate_PARAM_VALUE.AXI_DATA_WIDTH { PARAM_VALUE.AXI_DATA_WIDTH } {
  set v [get_property value ${PARAM_VALUE.AXI_DATA_WIDTH}]
  if {![string is integer -strict $v] || $v != 64} {
    set_property errmsg "AXI_DATA_WIDTH must be 64 (32-bit peripheral to 64-bit AXI conversion is hardcoded)" ${PARAM_VALUE.AXI_DATA_WIDTH}
    return false
  }
  return true
}
proc validate_PARAM_VALUE.AXI_USER_WIDTH { PARAM_VALUE.AXI_USER_WIDTH } {
  set v [get_property value ${PARAM_VALUE.AXI_USER_WIDTH}]
  if {![string is integer -strict $v] || $v < 0} {
    set_property errmsg "AXI_USER_WIDTH must be an integer >= 0" ${PARAM_VALUE.AXI_USER_WIDTH}
    return false
  }
  return true
}
proc validate_PARAM_VALUE.AXI_ID_WIDTH { PARAM_VALUE.AXI_ID_WIDTH PARAM_VALUE.PER_ID_WIDTH } {
  set axi_id [get_property value ${PARAM_VALUE.AXI_ID_WIDTH}]
  set per_id [get_property value ${PARAM_VALUE.PER_ID_WIDTH}]
  if {![string is integer -strict $axi_id] || $axi_id < 1} {
    set_property errmsg "AXI_ID_WIDTH must be an integer >= 1" ${PARAM_VALUE.AXI_ID_WIDTH}
    return false
  }
  # AXI_ID_WIDTH must fit binary encoding of PER_ID_WIDTH one-hot IDs
  set required 0
  set tmp $per_id
  while {$tmp > 1} { incr required; set tmp [expr {$tmp >> 1}] }
  if {$axi_id < $required} {
    set_property errmsg "AXI_ID_WIDTH must be >= ceil(log2(PER_ID_WIDTH=$per_id)) = $required" ${PARAM_VALUE.AXI_ID_WIDTH}
    return false
  }
  return true
}
proc validate_PARAM_VALUE.AXI_STRB_WIDTH { PARAM_VALUE.AXI_STRB_WIDTH PARAM_VALUE.AXI_DATA_WIDTH } {
  set strb [get_property value ${PARAM_VALUE.AXI_STRB_WIDTH}]
  set data [get_property value ${PARAM_VALUE.AXI_DATA_WIDTH}]
  if {[string is integer -strict $data] && $data > 0} {
    set expected [expr {$data / 8}]
    if {![string is integer -strict $strb] || $strb != $expected} {
      set_property errmsg "AXI_STRB_WIDTH must equal AXI_DATA_WIDTH/8 = $expected" ${PARAM_VALUE.AXI_STRB_WIDTH}
      return false
    }
  }
  return true
}

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
