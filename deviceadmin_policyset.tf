
## Create the Device Admin Policy Set -- Routers and Switches

resource "ise_device_admin_policy_set" "ps_router_switch" {
  depends_on = [
    ise_allowed_protocols_tacacs.pap_ascii,
    ise_network_device_group.ndg_cisco_switch,
    ise_network_device_group.ndg_cisco_router
   ]
  name                = "Routers and Switches"
  description         = ""
  rank                = 0
  service_name        = ise_allowed_protocols_tacacs.pap_ascii.name
  state               = "enabled"
  condition_type      = "ConditionOrBlock"
  condition_is_negate = false
  children = [
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "DEVICE"
      attribute_name  = "Device Type"
      operator        = "equals"
      attribute_value = "All Device Types#Cisco Router"
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "DEVICE"
      attribute_name  = "Device Type"
      operator        = "equals"
      attribute_value = "All Device Types#Cisco Switch"
    }
  ]
}

## Create Device Admin Policy Set -- Wireless Controllers

resource "ise_device_admin_policy_set" "ps_wlc" {
  depends_on = [ 
    ise_device_admin_policy_set.ps_router_switch,
    ise_allowed_protocols_tacacs.pap_ascii,
    ise_network_device_group.ndg_cisco_wlc
  ]
  name                      = "Wireless Controllers"
  description               = ""
  rank                      = 1
  service_name              = ise_allowed_protocols_tacacs.pap_ascii.name
  state                     = "enabled"
  condition_type            = "ConditionAttributes"
  condition_is_negate       = false
  condition_dictionary_name = "DEVICE"
  condition_attribute_name  = ise_network_device_group.ndg_cisco_wlc.root_group
  condition_operator        = "equals"
  condition_attribute_value = "All Device Types#Cisco WLC"
}

## Create Authentication Policies -- Routers and Switches

resource "ise_device_admin_authentication_rule" "authc_router_switch_pap" {
  depends_on = [
    ise_device_admin_policy_set.ps_router_switch
   ]
  policy_set_id             = ise_device_admin_policy_set.ps_router_switch.id
  name                      = "PAP"
  default                   = false
  rank                      = 0
  state                     = "enabled"
  condition_type            = "ConditionAttributes"
  condition_is_negate       = false
  condition_dictionary_name = "Network Access"
  condition_attribute_name  = "AuthenticationMethod"
  condition_operator        = "equals"
  condition_attribute_value = "PAP_ASCII"
  identity_source_name      = ise_active_directory_join_point.corp_ad.name
  if_auth_fail              = "REJECT"
  if_process_fail           = "DROP"
  if_user_not_found         = "REJECT"
}

## Create Authorization Policies - Routers and Switches

resource "ise_device_admin_authorization_rule" "authz_router_switch_readonly" {
  depends_on = [
    ise_device_admin_policy_set.ps_router_switch,
    time_sleep.ad_group_wait,
    data.ise_active_directory_groups_by_domain.net_monitor,
    ise_network_device_group.ndg_cisco_router,
    ise_network_device_group.ndg_cisco_switch
   ]
  policy_set_id       = ise_device_admin_policy_set.ps_router_switch.id
  name                = "Router Switch ReadOnly"
  default             = false
  rank                = 0
  state               = "enabled"
  command_sets        = [ise_tacacs_command_set.permit_show_commands.name]
  profile             = ise_tacacs_profile.ios_admin_priv10.name
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    condition_type = "ConditionOrBlock"
    is_negate      = false
    children = [
      {
        condition_type  = "ConditionAttributes"
        is_negate       = false
        dictionary_name = "DEVICE"
        attribute_name  = ise_network_device_group.ndg_cisco_router.root_group
        operator        = "equals"
        attribute_value = "All Device Types#Cisco Router"
      },
      {
        condition_type  = "ConditionAttributes"
        is_negate       = false
        dictionary_name = "DEVICE"
        attribute_name  = ise_network_device_group.ndg_cisco_switch.root_group
        operator        = "equals"
        attribute_value = "All Device Types#Cisco Switch"
      }
    ]
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.net_monitor.groups[0].name
  }]
}

resource "ise_device_admin_authorization_rule" "authz_router_switch_admin" {
  depends_on = [
    ise_device_admin_authorization_rule.authz_router_switch_readonly,
    time_sleep.ad_group_wait,
    data.ise_active_directory_groups_by_domain.net_admin
   ]
  policy_set_id       = ise_device_admin_policy_set.ps_router_switch.id
  name                = "Router Switch Admin"
  default             = false
  rank                = 1
  state               = "enabled"
  command_sets        = [ise_tacacs_command_set.permit_all_commands.name]
  profile             = ise_tacacs_profile.ios_admin_priv15.name
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    condition_type = "ConditionOrBlock"
    is_negate      = false
    children = [
      {
        condition_type  = "ConditionAttributes"
        is_negate       = false
        dictionary_name = "DEVICE"
        attribute_name  = ise_network_device_group.ndg_cisco_router.root_group
        operator        = "equals"
        attribute_value = "All Device Types#Cisco Router"
      },
      {
        condition_type  = "ConditionAttributes"
        is_negate       = false
        dictionary_name = "DEVICE"
        attribute_name  = ise_network_device_group.ndg_cisco_switch.root_group
        operator        = "equals"
        attribute_value = "All Device Types#Cisco Switch"
      }
    ]
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.net_admin.groups[0].name
  }]
}

## Create Authentication Policies -- Wireless Controllers

resource "ise_device_admin_authentication_rule" "authc_wlc_pap" {
  depends_on = [
    ise_device_admin_policy_set.ps_wlc
   ]
  policy_set_id             = ise_device_admin_policy_set.ps_wlc.id
  name                      = "PAP"
  default                   = false
  rank                      = 0
  state                     = "enabled"
  condition_type            = "ConditionAttributes"
  condition_is_negate       = false
  condition_dictionary_name = "Network Access"
  condition_attribute_name  = "AuthenticationMethod"
  condition_operator        = "equals"
  condition_attribute_value = "PAP_ASCII"
  identity_source_name      = ise_active_directory_join_point.corp_ad.name
  if_auth_fail              = "REJECT"
  if_process_fail           = "DROP"
  if_user_not_found         = "REJECT"
}

## Create Authorization Policies - Wireless Controllers

resource "ise_device_admin_authorization_rule" "authz_aireos_wlc_readonly" {
  depends_on = [
    ise_device_admin_policy_set.ps_wlc,
    time_sleep.ad_group_wait,
    data.ise_active_directory_groups_by_domain.net_monitor
   ]
  policy_set_id       = ise_device_admin_policy_set.ps_wlc.id
  name                = "AireOS WLC Monitor"
  default             = false
  rank                = 0
  state               = "enabled"
  profile             = data.ise_tacacs_profile.wlc_monitor.name
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "DEVICE"
      attribute_name  = ise_network_device_group.ndg_wlc_aireos.root_group
      operator        = "equals"
      attribute_value = "WLC OS Type#AireOS"
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.net_monitor.groups[0].name
    }
  ]
}


resource "ise_device_admin_authorization_rule" "authz_aireos_wlc_admin" {
  depends_on = [
    ise_device_admin_authorization_rule.authz_aireos_wlc_readonly,
    time_sleep.ad_group_wait,
    data.ise_active_directory_groups_by_domain.net_admin
   ]
  policy_set_id       = ise_device_admin_policy_set.ps_wlc.id
  name                = "AireOS WLC Admin"
  default             = false
  rank                = 1
  state               = "enabled"
  profile             = data.ise_tacacs_profile.wlc_all.name
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "DEVICE"
      attribute_name  = ise_network_device_group.ndg_wlc_aireos.root_group
      operator        = "equals"
      attribute_value = "WLC OS Type#AireOS"
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.net_admin.groups[0].name
    }
  ]
}

resource "ise_device_admin_authorization_rule" "authz_iosxe_wlc_readonly" {
  depends_on = [
    ise_device_admin_authorization_rule.authz_aireos_wlc_admin,
    time_sleep.ad_group_wait,
    data.ise_active_directory_groups_by_domain.net_monitor
   ]
  policy_set_id       = ise_device_admin_policy_set.ps_wlc.id
  name                = "IOS-XE WLC Monitor"
  default             = false
  rank                = 2
  state               = "enabled"
  profile             = ise_tacacs_profile.ios_admin_priv10.name
  command_sets        = [ise_tacacs_command_set.permit_show_commands.name]
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "DEVICE"
      attribute_name  = ise_network_device_group.ndg_wlc_iosxe.root_group
      operator        = "equals"
      attribute_value = "WLC OS Type#IOS-XE"
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.net_monitor.groups[0].name
    }
  ]
}

resource "ise_device_admin_authorization_rule" "authz_iosxe_wlc_admin" {
  depends_on = [
    ise_device_admin_authorization_rule.authz_iosxe_wlc_readonly,
    time_sleep.ad_group_wait,
    data.ise_active_directory_groups_by_domain.net_admin
   ]
  policy_set_id       = ise_device_admin_policy_set.ps_wlc.id
  name                = "IOS-XE WLC Admin"
  default             = false
  rank                = 3
  state               = "enabled"
  profile             = ise_tacacs_profile.ios_admin_priv15.name
  command_sets        = [ise_tacacs_command_set.permit_all_commands.name]
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "DEVICE"
      attribute_name  = ise_network_device_group.ndg_wlc_iosxe.root_group
      operator        = "equals"
      attribute_value = "WLC OS Type#IOS-XE"
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.net_admin.groups[0].name
    }
  ]
}
