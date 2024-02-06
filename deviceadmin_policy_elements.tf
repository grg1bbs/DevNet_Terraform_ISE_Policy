## Create Device Admin Allowed Protocols List - PAP_ASCII

resource "ise_allowed_protocols_tacacs" "pap_ascii" {
  name             = "PAP"
  description      = ""
  allow_pap_ascii  = true
  allow_chap       = false
  allow_ms_chap_v1 = false
}

## Create Network Device Groups for WLC OS Type - AireOS vs. IOS-XE

resource "ise_network_device_group" "ndg_wlc_os_type" {
  description = "Root Group for WLC OS Type"
  name        = "WLC OS Type#WLC OS Type"
  root_group  = "WLC OS Type"
}

resource "ise_network_device_group" "ndg_wlc_airos" {
  depends_on = [ 
    ise_network_device_group.ndg_wlc_os_type
   ]
  description = "AirOS WLCs"
  name        = "WLC OS Type#WLC OS Type#AireOS"
  root_group  = "WLC OS Type"
}

resource "ise_network_device_group" "ndg_wlc_iosxe" {
  depends_on = [ 
    ise_network_device_group.ndg_wlc_os_type
   ]
  description = "IOS-XE WLCs"
  name        = "WLC OS Type#WLC OS Type#IOS-XE"
  root_group  = "WLC OS Type"
}

## Create Network Device Groups -- Cisco routers, switches, and WLCs

resource "ise_network_device_group" "ndg_cisco_switch" {
  description = "Cisco IOS/IOS-XE switches"
  name        = "Device Type#All Device Types#Cisco Switch"
  root_group  = "Device Type"
}

resource "ise_network_device_group" "ndg_cisco_router" {
  depends_on = [
    ise_network_device_group.ndg_cisco_switch
   ]
  description = "Cisco IOS/IOS-XE routers"
  name        = "Device Type#All Device Types#Cisco Router"
  root_group  = "Device Type"
}

resource "ise_network_device_group" "ndg_cisco_wlc" {
  depends_on = [
  ise_network_device_group.ndg_cisco_router
  ]
  description = "Cisco Wireless LAN Controllers"
  name        = "Device Type#All Device Types#Cisco WLC"
  root_group  = "Device Type"
}

## Create TACACS Command Sets

resource "ise_tacacs_command_set" "permit_all_commands" {
  name             = "PermitAllCommands"
  permit_unmatched = true
}

resource "ise_tacacs_command_set" "permit_show_commands" {
  name             = "PermitShowCommands"
  permit_unmatched = false
  commands = [
    {
      grant     = "PERMIT"
      command   = "show"
      arguments = "*"
    }
  ]
}

## Get IDs for default TACACS Profiles -- 'WLC ALL' AND 'WLC MONITOR'

data "ise_tacacs_profile" "wlc_all" {
  name = "WLC ALL"
}

data "ise_tacacs_profile" "wlc_monitor" {
  name = "WLC MONITOR"
}

## Create TACACS Profiles

resource "ise_tacacs_profile" "ios_admin_priv10" {
  name        = "IOS_Admin_Priv10"
  description = "Privilege 10 access for IOS/IOS-XE"
  session_attributes = [
    {
      type  = "MANDATORY"
      name  = "priv-lvl"
      value = "10"
    }
  ]
}

resource "ise_tacacs_profile" "ios_admin_priv15" {
  name        = "IOS_Admin_Priv15"
  description = "Privilege 15 access for IOS/IOS-XE"
  session_attributes = [
    {
      type  = "MANDATORY"
      name  = "priv-lvl"
      value = "15"
    }
  ]
}
