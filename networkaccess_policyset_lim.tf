## Issue a 10 second sleep timer before creating the Network Access Policy Set
## This is necessary to mitigate a race condition with the creation of the Network Device Groups and Allowed Protocols

resource "time_sleep" "lim_wait_10_seconds" {
  depends_on = [
    ise_allowed_protocols.mab_dot1x,
    ise_network_device_group.ndg_deployment_stage,
    ise_network_device_group.ndg_lim,
    ise_network_access_policy_set.ps_wired_mm
  ]
  create_duration = "10s"
}

## Create the Policy Set for Wired Low Impact Mode

resource "ise_network_access_policy_set" "ps_wired_lim" {
  depends_on = [
    time_sleep.lim_wait_10_seconds
  ]
  name                = var.ps_wired_lim_name
  description         = "Wired Low Impact Mode"
  rank                = 1
  service_name        = ise_allowed_protocols.mab_dot1x.name
  state               = "enabled"
  is_proxy            = false
  condition_is_negate = false
  condition_type      = "ConditionAndBlock"
  children = [
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "Radius"
      attribute_name  = "NAS-Port-Type"
      operator        = "equals"
      attribute_value = "Ethernet"
    },
    {
      condition_type  = "ConditionAttributes"
      is_negate       = false
      dictionary_name = "DEVICE"
      attribute_name  = ise_network_device_group.ndg_deployment_stage.root_group
      operator        = "equals"
      attribute_value = "Deployment Stage#Low Impact Mode"
    },
  ]
}

## Create Wired LIM AuthC Policy - Dot1x TEAP

resource "ise_network_access_authentication_rule" "lim_authc_teap" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_lim
  ]
  name                 = var.authc_policy_teap
  rank                 = 0
  state                = "enabled"
  identity_source_name = ise_identity_source_sequence.iss_ad_cert.name
  if_auth_fail         = "REJECT"
  if_process_fail      = "DROP"
  if_user_not_found    = "REJECT"
  policy_set_id        = ise_network_access_policy_set.ps_wired_lim.id
  default              = false
  condition_is_negate  = false
  condition_type       = "ConditionAndBlock"
  children = [
    {
      is_negate      = false
      condition_type = "ConditionReference"
      id             = data.ise_network_access_condition.wired_dot1x.id
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = "Network Access"
      attribute_name  = "EapTunnel"
      operator        = "equals"
      attribute_value = "TEAP"
    }
  ]
}

## Create Wired LIM AuthC Policy - Dot1x EAP-TLS

resource "ise_network_access_authentication_rule" "lim_authc_eaptls" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_lim
  ]
  name                 = var.authc_policy_eaptls
  rank                 = 1
  state                = "enabled"
  identity_source_name = ise_identity_source_sequence.iss_ad_cert.name
  if_auth_fail         = "REJECT"
  if_process_fail      = "DROP"
  if_user_not_found    = "REJECT"
  policy_set_id        = ise_network_access_policy_set.ps_wired_lim.id
  default              = false
  condition_is_negate  = false
  condition_type       = "ConditionAndBlock"
  children = [
    {
      is_negate      = false
      condition_type = "ConditionReference"
      id             = data.ise_network_access_condition.wired_dot1x.id
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = "Network Access"
      attribute_name  = "EapAuthentication"
      operator        = "equals"
      attribute_value = "EAP-TLS"
    }
  ]
}

## Create Wired LIM AuthC Policy - MAB

resource "ise_network_access_authentication_rule" "lim_authc_mab" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_lim,
    ise_network_access_authentication_rule.lim_authc_eaptls
  ]
  name                 = var.authc_policy_mab
  rank                 = 2
  state                = "enabled"
  identity_source_name = "Internal Endpoints"
  if_auth_fail         = "REJECT"
  if_process_fail      = "DROP"
  if_user_not_found    = "CONTINUE"
  policy_set_id        = ise_network_access_policy_set.ps_wired_lim.id
  default              = false
  condition_is_negate  = false
  condition_type       = "ConditionReference"
  condition_id         = data.ise_network_access_condition.wired_mab.id
}

## Create Wired LIM AuthZ Policy Rule 1 - AD User TEAP

resource "ise_network_access_authorization_rule" "lim_authz_ad_user_teap" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_lim,
    ise_active_directory_add_groups.ad_domain_groups
  ]
  policy_set_id = ise_network_access_policy_set.ps_wired_lim.id
  profiles = [
    ise_authorization_profile.lim_authz_ad_user.name
  ]
  default             = false
  name                = "${var.authz_policy_ad_user} EAP Chained"
  rank                = 0
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate       = false
    condition_type  = "ConditionAttributes"
    dictionary_name = "Network Access"
    attribute_name  = "EapTunnel"
    operator        = "equals"
    attribute_value = "TEAP"
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_users.groups[0].name
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_computers.groups[0].name
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = "Network Access"
      attribute_name  = "EapChainingResult"
      operator        = "equals"
      attribute_value = "User and machine both succeeded"
    }
  ]
  security_group = ise_trustsec_security_group.sgt_corp_user.name
}

## Create Wired LIM AuthZ Policy Rule 2 - AD Computer TEAP

resource "ise_network_access_authorization_rule" "lim_authz_ad_computer_teap" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_lim,
    ise_network_access_authorization_rule.lim_authz_ad_user_teap,
    ise_active_directory_add_groups.ad_domain_groups
  ]
  policy_set_id = ise_network_access_policy_set.ps_wired_lim.id
  profiles = [
    ise_authorization_profile.lim_authz_ad_computer.name
  ]
  default             = false
  name                = "${var.authz_policy_ad_computer} TEAP"
  rank                = 1
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate       = false
    condition_type  = "ConditionAttributes"
    dictionary_name = "Network Access"
    attribute_name  = "EapTunnel"
    operator        = "equals"
    attribute_value = "TEAP"
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_computers.groups[0].name
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = "Network Access"
      attribute_name  = "EapChainingResult"
      operator        = "equals"
      attribute_value = "User failed and machine succeeded"
    }
  ]
  security_group = ise_trustsec_security_group.sgt_corp_user.name
}

## Create Wired LIM AuthZ Policy Rule 3 - AD User

resource "ise_network_access_authorization_rule" "lim_authz_ad_user_eaptls" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_lim,
    ise_active_directory_add_groups.ad_domain_groups,
    ise_network_access_authorization_rule.lim_authz_ad_user_teap,
    ise_network_access_authorization_rule.lim_authz_ad_computer_teap,
  ]
  policy_set_id = ise_network_access_policy_set.ps_wired_lim.id
  profiles = [
    ise_authorization_profile.lim_authz_ad_user.name
  ]
  default             = false
  name                = "${var.authz_policy_ad_user} EAP-TLS"
  rank                = 2
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate       = false
    condition_type  = "ConditionAttributes"
    dictionary_name = "Network Access"
    attribute_name  = "EapAuthentication"
    operator        = "equals"
    attribute_value = "EAP-TLS"
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_users.groups[0].name
    }
  ]
  security_group = ise_trustsec_security_group.sgt_corp_user.name
}

## Create Wired LIM AuthZ Policy Rule 4 - AD Computer

resource "ise_network_access_authorization_rule" "lim_authz_ad_computer_eaptls" {
  depends_on = [
    ise_network_access_policy_set.ps_wired_lim,
    ise_active_directory_add_groups.ad_domain_groups,
    ise_network_access_authorization_rule.lim_authz_ad_user_teap,
    ise_network_access_authorization_rule.lim_authz_ad_computer_teap,
    ise_network_access_authorization_rule.lim_authz_ad_user_eaptls,
  ]
  policy_set_id = ise_network_access_policy_set.ps_wired_lim.id
  profiles = [
    ise_authorization_profile.lim_authz_ad_computer.name
  ]
  default             = false
  name                = "${var.authz_policy_ad_computer} EAP-TLS"
  rank                = 3
  state               = "enabled"
  condition_type      = "ConditionAndBlock"
  condition_is_negate = false
  children = [{
    is_negate       = false
    condition_type  = "ConditionAttributes"
    dictionary_name = "Network Access"
    attribute_name  = "EapAuthentication"
    operator        = "equals"
    attribute_value = "EAP-TLS"
    },
    {
      is_negate       = false
      condition_type  = "ConditionAttributes"
      dictionary_name = ise_active_directory_join_point.corp_ad.name
      attribute_name  = "ExternalGroups"
      operator        = "equals"
      attribute_value = data.ise_active_directory_groups_by_domain.domain_computers.groups[0].name
    }
  ]
  security_group = ise_trustsec_security_group.sgt_corp_user.name
}

## Update Wired_LIM Default AuthZ Policy Rule to replace 'DenyAccess' with 'LIM-AuthZ-Default' AuthZ Profile -- ISSUE OPEN

/*

data "ise_network_access_authorization_rule" "lim_authz_rules" {
#  depends_on = [
#    ise_network_access_authorization_rule.lim_authz_ad_user,
#    ise_network_access_authorization_rule.lim_authz_ad_computer
#  ]
  policy_set_id = ise_network_access_policy_set.ps_wired_lim.id
  name = "Default"
}



## Update Wired_LIM Default AuthZ Policy Rule to replace 'DenyAccess' with 'LIM-AuthZ-Default' AuthZ Profile -- BUG OPEN

resource "ciscoise_network_access_authorization_rules_update" "lim_authz_default" {
  provider = ciscoise
  depends_on = [
    ciscoise_network_access_authorization_rules.lim_authz_ad_user,
    ciscoise_network_access_authorization_rules.lim_authz_ad_computer
  ]
  parameters {
    policy_id = ciscoise_network_access_policy_set.ps_wired_lim.parameters[0].id
    id        = data.ciscoise_network_access_authorization_rules.lim_authz_rules.items[2].rule[0].id
    profile = [
      "lim-AuthZ-Default"
    ]
    rule {
      name    = "Default"
      rank    = 2
      state   = "enabled"
      default = true
    }
  }
}

*/